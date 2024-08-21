function [Xcal,Xtest] = preprocess_cguo(Xcal,Xtest,p)
%UNTITLED3 Summary of this function goes here
%   Written by Guo Cheng
%   p: 0:null  1:Smooth  2:SNV  3:MSC  4:Deriv 5:CWT

% disp('      %%%%%%     %%%%%%  ')
% disp([' 0:null ',' 1:Smooth ', ' 2:SNV ', ' 3:MSC ', ' 4:Deriv ','5:CWT'])
% disp('      %%%%%%     %%%%%%  ')
% p=input('选择预处理方法(preprocess method)：');
if p==0
    % null
    Xcal=Xcal;
    Xtest=Xtest;
elseif p==1
    % Moving window smoothing
    [Xcal_smo]=smooth(Xcal,5); % 5: Spectral window size; X is the data matrix of mean spectra
    [Xtest_smo]=smooth(Xtest,5); % 5: Spectral window size; X is the data matrix of mean spectra
    Xcal=Xcal_smo;
    Xtest=Xtest_smo;

elseif p==2
    % SNV(Standard normal transformation)
    [Xcal_snv,~,~,Xtest_snv]=snv2(Xcal,Xtest);
    Xcal=Xcal_snv;
    Xtest=Xtest_snv;

elseif p==3
    % MSC(Multiplicative scattering correction)
    [Xcal_msc,~,Xtest_msc]=msc(Xcal,1,size(Xcal,2),Xtest); % 1: first variable used for correction, size(X,2): last variable used for correction
    Xcal=Xcal_msc;
    Xtest=Xtest_msc;

elseif p==4
    % S/G 1st der(Savitzky-Golay first-derivative)
    [Xcal_de]=deriv(Xcal,1,5,2);% 1:degree of the derivative; 5:Spectral window size; 2:the order of the polynomial
    [Xtest_de]=deriv(Xtest,1,5,2);
    Xcal=Xcal_de;
    Xtest=Xtest_de;
else
    % CWT   
    [Xcal_cwt]=wavederive(Xcal,'sym2',20);
    [Xtest_cwt]=wavederive(Xtest,'sym2',20);
    Xcal=Xcal_cwt;
    Xtest=Xtest_cwt;
    
end

end

