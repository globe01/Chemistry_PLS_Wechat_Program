function [slope,intercept,STAT]=myregr(x,y,varargin)
%MYREGR: Perform a least-squares linear regression.
%This function computes a least-square linear regression suppling several
%output information.
%
% Syntax: 	myregr(x,y)
%      
%     Inputs:
%           X - Array of the independent variable 
%           Y - Dependent variable. If Y is a matrix, the i-th Y row is a
%           repeated measure of i-th X point. The mean value will be used
%           verbose - Flag to display all information (default=1)
%     Outputs:
%           - Slope with standard error an 95% C.I.
%           - Intercept with standard error an 95% C.I.
%           - Pearson's Correlation coefficient with 95% C.I. and its
%             adjusted form (depending on the elements of X and Y arrays)
%           - Spearman's Correlation coefficient
%           - Regression Standard Error
%           - Total Variability
%           - Variability due to regression
%           - Residual Variability
%           - Student's t-Test on Slope (to check if slope=0)
%           - Student's t-Test on Intercept (to check if intercept=0)
%           - Modified Levene's test for homoschedasticity of residuals
%           - Power of the regression
%           - Deming's regeression
%           - a plot with:
%                o Data points
%                o Least squares regression line
%                o Red dotted lines: 95% Confidence interval of regression
%                o Green dotted lines: 95% Confidence interval of new y 
%                                       evaluation using this regression.
%           - Residuals plot
%
%   [Slope]=myregr(...) returns a structure of slope containing value, standard
%   error, lower and upper bounds 95% C.I.
%
%   [Slope,Intercept]=myregr(...) returns a structure of slope and intercept 
%   containing value, standard error, lower and upper bounds 95% C.I.
%
%   [Slope,Intercept,STATS]= also returns a STATS structure with several
%   informations.
%
% Example:
%       x = [1.0 2.3 3.1 4.8 5.6 6.3];
%       y = [2.6 2.8 3.1 4.7 4.1 5.3];
%
%   Calling on Matlab the function: 
%             myregr(x,y)
%
%   Answer is:
%
% REGRESSION SETTING X AS INDEPENDENT VARIABLE
% --------------------------------------------------------------------------------
%                   Value     Standard_Error    Lower_bound    Upper_bound
%                  _______    ______________    ___________    ___________
% 
%     Slope        0.50107    0.096671          0.23267        0.76947    
%     Intercept     1.8376      0.4139          0.68838         2.9867    
% 
% 			Correlation Coefficients
% --------------------------------------------------------------------------------
%                  Value     Standard_Error    Lower_bound    Upper_bound    Adjusted
%                 _______    ______________    ___________    ___________    ________
% 
%     Pearson     0.93296    0.17999           0.49988        0.99281        0.9162  
%     Spearman    0.94286        NaN           0.55913         0.9939           NaN  
% 
% 			Variability
% --------------------------------------------------------------------------------
%                 Value     Total     By_Regression    Percent1    Residual    Percent2
%                _______    ______    _____________    ________    ________    ________
% 
%     Regr_SE    0.44358    6.0733    5.2863           87.041      0.78706     12.959  
% 
%  
% Statistical tests
% --------------------------------------------------------------------------------
%                    t       critical_t     p_value      Power         Comment     
%                  ______    __________    _________    _______    ________________
% 
%     Slope        5.1832    2.7764        0.0065916    0.98101    'slope ~= 0'    
%     Intercept    4.4396    2.7764         0.011338    0.95888    'intercept ~= 0'
%     Residuals    0.5067    2.7764          0.31951        NaN    'Homoschedastic'
% 
% Power of regression
% --------------------------------------------------------------------------------
%     alpha    points      Z         Sd       Power_of_regression
%     _____    ______    ______    _______    ___________________
% 
%     0.05     6         1.6807    0.57735    0.60459            
% 
%  
% OTHER REGRESSIONS
% REGRESSION SETTING Y AS INDEPENDENT VARIABLE
% --------------------------------------------------------------------------------
%     mean_x    dev_x     mean_y    dev_y     codev     slope     intercept
%     ______    ______    ______    ______    _____    _______    _________
% 
%     3.85      21.055    3.7667    6.0733    10.55    0.57567    1.5503   
% 
%  
% DEMING'S REGRESSION
% --------------------------------------------------------------------------------
%     Lambda     slope     intercept
%     ______    _______    _________
% 
%     3.4668    0.53708    1.6989   
%
% ...and the plot, of course.
%
% SEE also myregrinv, myregrcomp
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
%
% To cite this file, this would be an appropriate format:
% Cardillo G. (2007) MyRegression: a simple function on LS linear
% regression with many informative outputs. 
% http://www.mathworks.com/matlabcentral/fileexchange/15473

%Input error handling
p = inputParser;
addRequired(p,'x',@(x) validateattributes(x,{'numeric'},{'row','real','finite','nonnan','nonempty'}));
addRequired(p,'y',@(x) validateattributes(x,{'numeric'},{'2d','real','finite','nonnan','nonempty'}));
addOptional(p,'verbose',1, @(x) isnumeric(x) && isreal(x) && isfinite(x) && isscalar(x) && (x==0 || x==1));
parse(p,x,y,varargin{:});
verbose=p.Results.verbose; alpha=0.05;
clear p
x=x(:);
if isvector(y)
    yt=y(:); %columns vectors
else
    yt=mean(y)';
end
assert(length(x)==length(yt),'X and Y arrays must have the same numbers of columns.');

ux=unique(x); 
if length(ux)~=length(x)
    uy=zeros(size(ux));
    for I=1:length(ux)
        c=sum(x==ux(I));
        if c==1
            uy(I)=yt(x==ux(I));
        else
            uy(I)=mean(yt(x==ux(I)));
        end
    end
    x=ux(:); yt=uy(:); 
    clear uy I
end
clear ux

xtmp=[x ones(length(x),1)]; %input matrix for regress function
ytmp=yt;

%regression coefficients
[p,pINT,R,Rint] = regress(ytmp,xtmp);

%check the presence of outliers
outl=find(ismember(sign(Rint),[-1 1],'rows')==0);
if ~isempty(outl) 
    disp('These points are outliers at 95% fiducial level')
    disp(array2table([xtmp(outl) ytmp(outl)],'VariableNames',{'X' 'Y'}))
    reply = input('Do you want to delete outliers? Y/N [Y]: ', 's');
    disp(' ')
    if isempty(reply) || upper(reply)=='Y'
        ytmp(outl)=[]; xtmp(outl,:)=[];
        [p,pINT,R] = regress(ytmp,xtmp);
    end
end

xtmp(:,2)=[]; %delete column 2
%save coefficients value
m(1)=p(1); q(1)=p(2);

n=length(xtmp); 
xm=mean(xtmp); xsd=std(xtmp);

%standard error of regression coefficients
%Student's critical value
if isvector(y)
    cv=tinv(0.975,n-2); 
else
    cv=tinv(0.975,sum(size(y))-3);
end
m(2)=(pINT(3)-p(1))/cv; %slope standard error
m=[m pINT(1,:)]; %add slope 95% C.I.
q(2)=(pINT(4)-p(2))/cv; %intercept standard error
q=[q pINT(2,:)]; %add intercept 95% C.I.

slope.value=m(1); slope.se=m(2); slope.lv=m(3); slope.uv=m(4);
intercept.value=q(1); intercept.se=q(2); intercept.lv=q(3); intercept.uv=q(4);

%Pearson's Correlation coefficient
[rp,pr,rlo,rup]=corrcoef(xtmp,ytmp);
r(1)=rp(2); r(2)=realsqrt((1-r(1)^2)/(n-2)); r(3)=rlo(2); r(4)=rup(2); 
%Adjusted Pearson's Correlation coefficient
r(5)=sign(r(1))*(abs(r(1))-((1-abs(r(1)))/(n-2)));

%Spearman's Correlation coefficient
[rx]=tiedrank(xtmp);
[ry]=tiedrank(ytmp);
d=rx-ry;
sp=1-(6*sum(d.^2)/(n^3-n));
rs=[sp NaN tanh(atanh(sp)+[-1 1].*(1.96/realsqrt(n-3))) NaN];


%Total Variability
ym=polyval(p,xm);
vtot=sum((ytmp-ym).^2);

%Regression Variability
ystar=ytmp-R;
vreg=sum((ystar-ym).^2);

%Residual Variability
vres=sum(R.^2);

%regression standard error (RSE)
if isvector(y)
    RSE=realsqrt(vres/(n-2));
else
    if ~isempty(outl) && (isempty(reply) || upper(reply)=='Y')
        y2=y; y2(outl)=[];
        RSE=realsqrt((vres+sum(sum((y2-repmat(ytmp',size(y,1),1)).^2)))/(sum(size(y2))-3));
    else
        RSE=realsqrt((vres+sum(sum((y-repmat(yt',size(y,1),1)).^2)))/(sum(size(y))-3));
    end
end

%Confidence interval at 95% of regression
sy=RSE*realsqrt(1/n+(((xtmp-xm).^2)/((n-1)*xsd^2)));
cir=[ystar+cv*sy ystar-cv*sy];

%Confidence interval at 95% of a new observation (this is the confidence
%interval that should be used when you evaluate a new y with a new observed
%x)
sy2=realsqrt(sy.^2+RSE^2);
cir2=[ystar+cv*sy2 ystar-cv*sy2];

STAT.rse=RSE; STAT.cv=cv; STAT.n=n;
STAT.xm=mean(x); STAT.ym=ym; STAT.sse=sum((xtmp-xm).^2); STAT.r=r;

%display results
if verbose==1
    tr=repmat('-',1,80);
    disp('REGRESSION SETTING X AS INDEPENDENT VARIABLE')
    disp(tr)
    disp(array2table([m;q],'RowNames',{'Slope','Intercept'},'VariableNames',{'Value','Standard_Error','Lower_bound','Upper_bound'}))
    fprintf('\t\t\tCorrelation Coefficients\n')
    disp(tr)
    disp(array2table([r;rs],'RowNames',{'Pearson','Spearman'},'VariableNames',{'Value','Standard_Error','Lower_bound','Upper_bound','Adjusted'}))
    fprintf('\t\t\tVariability\n')
    disp(tr)
    disp(array2table([RSE vtot vreg vreg/vtot*100 vres vres/vtot*100],'RowNames',{'Regr_SE'},'VariableNames',{'Value','Total','By_Regression','Percent1','Residual','Percent2'}))
    disp(' ')
 
    %test on slope
    sturegr=cell(3,5);
    sturegr{1,1}=abs(m(1)/m(2)); %Student's t
    sturegr{1,2}=cv; sturegr{1,3}=pr(2);
    if sturegr{1,1}>sturegr{1,2}
        sturegr{1,5}='slope ~= 0';
        sturegr{1,4}=1-tcdf(tinv(1-alpha,n-2) - sturegr{1,1},n-2);%Power estimation.
    else
        sturegr{1,5}='slope = 0';
        sturegr{1,4}=tcdf(sturegr{1,1} - tinv(1-alpha,n-2),n-2);%Power estimation.
        m(1)=0;
    end
    sturegr{2,1}=abs(q(1)/q(2)); %Student's t
    sturegr{2,2}=cv; sturegr{2,3}=(1-tcdf(sturegr{2,1},n-2))*2; %p-value
    if sturegr{2,1}>sturegr{2,2}
        sturegr{2,5}='intercept ~= 0';
        sturegr{2,4}=1-tcdf(tinv(1-alpha,n-2) - sturegr{2,1},n-2);%Power estimation.
    else
        sturegr{2,5}='intercept = 0';
        sturegr{2,4}=tcdf(sturegr{2,1} - tinv(1-alpha,n-2),n-2);%Power estimation.
        q(1)=0;
    end
    
    %Test for homoschedasticity of residuals (Modified Levene's test)
    xme=median(xtmp);
    e1=R(xtmp<=xme); me1=median(e1); d1=abs(e1-me1); dm1=mean(d1); l1=length(e1);
    e2=R(xtmp>xme);  me2=median(e2); d2=abs(e2-me2); dm2=mean(d2); l2=length(e2);
    gl=(l1+l2-2); S2p=(sum((d1-dm1).^2)+sum((d2-dm2).^2))/gl;
    sturegr{3,1}=abs(dm1-dm2)/realsqrt(S2p*(1/l1+1/l2)); sturegr{3,2}=tinv(1-alpha/2,gl); 
    sturegr{3,3}=(1-tcdf(sturegr{3,1},gl)); %p-value
    sturegr{3,4}=NaN;
    if sturegr{3,1}>sturegr{3,2}
        sturegr{3,5}='Heteroschedastic';
    else
        sturegr{3,5}='Homoschedastic';
    end
    disp('Statistical tests')
    disp(tr)
    disp(cell2table(sturegr,'VariableNames',{'t','critical_t','p_value','Power','Comment'},...
        'RowNames',{'Slope','Intercept','Residuals'}))

    %Power of regression
    Zrho=0.5*reallog((1+abs(r(1)))/(1-abs(r(1)))); %normalization of Pearson's correlation coefficient
    sZ=realsqrt(1/(n-3)); %std.dev of Zrho
    pwr=1-tcdf(1.96-Zrho/sZ,n-2)*2; %power of regression
    disp('Power of regression')
    disp(tr)
    disp(array2table([alpha n Zrho sZ pwr],'VariableNames',{'alpha','points','Z','Sd','Power_of_regression'}))
    
    n=length(xtmp);
    sx=sum(xtmp);
    sy=sum(ytmp);
    sx2=sum(xtmp.^2);
    sy2=sum(ytmp.^2);
    sxy=sum(xtmp.*ytmp);
    mx=mean(xtmp);
    my=mean(ytmp);
    vx=var(xtmp);
    vy=var(ytmp);
    lambda=vx/vy;
    devx=sx2-sx^2/n;
    devy=sy2-sy^2/n;
    codev=sxy-sx*sy/n;
    
    regrym=devy/codev;
    regryq=-regrym*(mx-codev/devy*my);
    disp(' ')
    disp('OTHER REGRESSIONS')
    disp('REGRESSION SETTING Y AS INDEPENDENT VARIABLE')
    disp(tr)
    disp(array2table([mx devx my devy codev regrym regryq],'VariableNames',{'mean_x','dev_x','mean_y','dev_y','codev','slope','intercept'}))
       
    demingm=(devy-((1/lambda)*devx))/(2*codev)+realsqrt(((devy-((1/lambda)*devx))/(2*codev))^2+(1/lambda));
    demingq=my-demingm*mx;
    disp(' ')
    disp('DEMING''S REGRESSION')
    disp(tr)
    disp(array2table([lambda demingm demingq],'VariableNames',{'Lambda','slope','intercept'}))
    
    %plot regression
    figure('Color',[1 1 1],'outerposition',get(groot,'ScreenSize'));
    subplot(1,2,1); 
    if isvector(y)        
        plot(x,yt,'bo',xtmp,ystar,xtmp,cir,'r:',xtmp,cir2,'g:');
    else       
        hold on
        plot(x',yt,'LineStyle','none','Marker','o','MarkerEdgeColor','b')
        plot(xtmp,ystar,'k',xtmp,cir,'r:',xtmp,cir2,'g:');
        hold off
    end
    axis square
    txt=sprintf('Red dotted lines: 95%% Confidence interval of regression\nGreen dotted lines: 95%% Confidence interval of new y evaluation using this regression');
    title(txt)
    %plot residuals
    subplot(1,2,2);
    xl=[min(x) max(x)];
    plot(xtmp,R,'bo',xl,[0 0],'k-',xl,[RSE RSE],'g--',xl,[-RSE -RSE],'g--',...
        xl,1.96.*[RSE RSE],'m--',xl,-1.96.*[RSE RSE],'m--',...
        xl,2.58.*[RSE RSE],'r--',xl,-2.58.*[RSE RSE],'r--')
    axis square
end