function x=myregrinv(xc,yc,yo,varargin)
% MYREGRINV: Resolve a calibration problem (inverse regression problem) that
% is: to estimate mean value and confidence interval of x since y.
% This function computes a least-square linear regression using the
% supplied calibration points and then computes the X values for a supplied
% y observed vector. This routine uses MYREGR function. If it is not present on
% the computer, myregrinv will try to download it from FEX
% References:
% Sokal R.R. and Rohlf F.J. 2003 BIOMETRY. The Principles and Practice of Statistics in Biological
% Research (3rd ed., 8th printing, Freeman and Company, New York, XIX + 887
% p.) pag. 491 - 493.
% 
% SEE also myregr, myregrcomp
% 
% Syntax: 	x=myregrinv(xc,yc,yo,verbose)
% 
%     Inputs:
%           xc - Array of the independent variable of calibration line
%           yc - Dependent variable of calibration line. If yc is a matrix, 
%                the i-th yc row is a repeated measure of i-th xc point. 
%                The mean value will be used
%           yo - Observed dependent variable of unknown samples. If yc is a
%                matrix, the i-th yo row is a repeated measure of i-th
%                unknown sample. The mean value will be used
%           verbose - Flag to display regress informations (default=1)
%     Outputs:
%           - All the outputs of MYREGR function
%           - Limit of detection (lod)
%           - Limit of quantification (loq)
%           - independent variable of unknown samples with 95% C.I.
% 
% Example:
%       xc = 0:2:12;
%       yc = [1.2 5 9 12.6 17.3 21 24.7];
%       yo = [1 2 6 22 30];
% 
%   Calling on Matlab the function: 
%             x=myregrinv(xc,yc,yo)
% 
%   Answer is:
% 
% (...) All the outputs of MYREGR function + calibration plot
% quality = 0.0010 < 0.1	 This is a good calibrator
%  
% Limit of detection (LOD): 1.6194	 x_LOD = 0.2625
% Limit of quantification (LOQ): 2.8315	 x_LOQ = 0.8751
%  
%                   Inverse Prediction Values
% ------------------------------------------------------------
%     1.0000          x<LOD
%     2.0000     LOD<=x<=LOQ
%     6.0000         2.4765         2.1033       2.8430
%    22.0000        10.5632        10.1868      10.9484
%    30.0000     Out of calibration interval
% ------------------------------------------------------------
% 
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
% 
% To cite this file, this would be an appropriate format:
% Cardillo G. (2007) MyRegressionINV: resolve a calibration problem that
% is: to estimate mean value and confidence interval of x since y. 
% http://www.mathworks.com/matlabcentral/fileexchange/15952

%Input error handling
p = inputParser;
addRequired(p,'xc',@(x) validateattributes(x,{'numeric'},{'row','real','finite','nonnan','nonempty','increasing'}));
addRequired(p,'yc',@(x) validateattributes(x,{'numeric'},{'2d','real','finite','nonnan','nonempty'}));
addRequired(p,'yo',@(x) validateattributes(x,{'numeric'},{'row','real','finite','nonnan','nonempty'}));
addOptional(p,'verbose',1, @(x) isnumeric(x) && isreal(x) && isfinite(x) && isscalar(x) && (x==0 || x==1));
parse(p,xc,yc,yo,varargin{:});
verbose=p.Results.verbose; 
clear p

%regression coefficients
assert(exist('myregr.m','file')~=0,'You must download myregr function from https://it.mathworks.com/matlabcentral/fileexchange/15473-myregression')

[m,q,stat] = myregr(xc,yc,verbose);
quality=((stat.cv*stat.rse/m.value)^2)/stat.sse;
disp(' ')
if quality>=0.1
    fprintf('quality = %0.4f >= 0.1\t This is not a good calibrator\n',quality)
else
    fprintf('quality = %0.4f < 0.1\t This is a good calibrator\n',quality)
end

%limit of detection (lod)
lod=q.value+3*q.se;
%limit of quantification (loq)
loq=lod+7*q.se;

if isvector(yo)
    yo=yo(:); %columns vectors
else
    yo=mean(yo,2);
end

%Inverse prediction
xo=((yo-q.value)./m.value);

%From Biostatistical Analysis by Jerrold H. Zar (4th edition, 1999, Prentice Hall, New Jersey, USA)
% K is a value depending from alpha and degrees of freedom of error
% variance; it can be estimated by tinv(alpha/2,n-2), the same used in
% Myregr function to test slope and intercept.
K=m.value^2-stat.cv^2*m.se^2;
a=((yo-stat.ym).^2)./stat.sse;
b=K*(1+1/stat.n);
c=stat.rse*realsqrt((a+b));
d=(stat.cv/K).*c;
e=stat.xm+(m.value.*(yo-stat.ym)./K);
f=repmat(e,1,2)+repmat([-1 1],length(yo),1).*repmat(d,1,2);
x=[xo f];

%display results
disp(' ')
fprintf('Limit of detection (LOD): %0.4f\t x_LOD = %0.4f\n',lod,((lod-q.value)./m.value))
fprintf('Limit of quantification (LOQ): %0.4f\t x_LOQ = %0.4f\n',loq,((loq-q.value)./m.value))
disp(' ')
tr=repmat('-',1,60);
disp('                  Inverse Prediction Values'); 
disp(tr)
if isvector(yc)
    calint=[min(yc) max(yc)];
else
    calint=[min(mean(yc,2)) max(mean(yc,2))];
end
for I=1:length(yo)
    if yo(I) > loq
        if yo(I)>=calint(1) && yo(I)<=calint(2)
            fprintf('%10.4f     %10.4f     %10.4f   %10.4f\n',yo(I),x(I,:));
        else
            fprintf('%10.4f     Out of calibration interval\n',yo(I));
            x(I,:)=NaN(1,3);
        end
    elseif yo(I)>lod && yo(I)<=loq
        fprintf('%10.4f     LOD<=x<=LOQ\n',yo(I));
        x(I,:)=NaN(1,3);
    elseif yo(I)<=lod
        fprintf('%10.4f          x<LOD\n',yo(I));
        x(I,:)=NaN(1,3);
    end
   
end
disp(tr)