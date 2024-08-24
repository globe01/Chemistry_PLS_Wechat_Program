function [ result ] = plspred_cguo( Xcal,ycal,Xtest,ytest,vsel,nLV,n_fold,pre_def_LV,isplot)
%   PLSPRED_ZJ Summary of this function goes here
if nargin<9;isplot=false;end
if nargin<8;pre_def_LV=nLV;end
if nargin<7;n_fold=5;end
if nargin<6;nLV=12;end
if nargin<5||isempty(vsel);vsel=1:size(Xcal,2);end

is_exist_test=(~isempty(Xtest)&&~isempty(ytest));


Xcal=Xcal(:,vsel);

[Xcal_c,Xcal_para1,Xcal_para2]=pretreat(Xcal,'center');
[ycal_c,ycal_para1,ycal_para2]=pretreat(ycal,'center');
[B]=simpls(Xcal_c,ycal_c,nLV);   % no pretreatment.
C=ycal_para2*B./Xcal_para2';
coef=[C;ycal_para1-Xcal_para1*C;];
%+++ predict
Xcale=[Xcal ones(size(Xcal,1),1)];

optLV=pre_def_LV;
yhat_cal=Xcale*coef;
[RMSEC ,R]=calc_rmsec(ycal,yhat_cal);
error_cal = yhat_cal-ycal;

[~,~,T,~,Q,W,~,~]=plsnipals(Xcal_c, ycal_c, nLV);
VIP=vip(Xcal_c,ycal_c,T,W,Q);

if ~isnan(n_fold)
    CV=plscv_cguo(Xcal,ycal,nLV,n_fold);
    optLV=min([optLV pre_def_LV, CV.optLV]);
    yhat_cv=CV.ypred;
    [RMSECV ,Rcv]=calc_rmsec(ycal,yhat_cv);
    error_cv = yhat_cv-ycal;
    SD=std(yhat_cv(:,optLV)); % 郭成修改
    RPD=SD/RMSECV(:,optLV);      % 郭成修改
    
end

if is_exist_test
    Xtest=Xtest(:,vsel);
    Xteste=[Xtest ones(size(Xtest,1),1)];
    yhat_test=Xteste*coef;
    error_test = yhat_test-ytest;
    [RMSEP ,Rp]=calc_rmsec(ytest,yhat_test);
%     SD=std(yhat_test(:,optLV)); % 郭成修改
%     RPD=SD/RMSEP(:,optLV);      % 郭成修改
end

%+++ plot
if isplot
    figure;
    plot(1:nLV,RMSEC,'ro-');hold on;
    legend1={'RMSEC'};
    if ~isnan(n_fold)
        plot(1:nLV,RMSECV,'go-');
        legend1=[legend1; 'RMSECV'];
    end
    if is_exist_test
        plot(1:nLV,RMSEP,'bo-');
        legend1=[legend1; 'RMSEP'];
    end
    plot([optLV optLV],[min([RMSEC RMSECV])*0.95 1.05*max([RMSEC RMSECV])],'k-','LineWidth',1);
    legend([legend1;'optLV']);legend boxoff;
    xlabel('nLV');ylabel('RMSE');

    figure;
    scatter(ycal,yhat_cal(:,optLV),'ro');hold on;
    legend2={'Calibration'};
    if ~isnan(n_fold)
        scatter(ycal,yhat_cv(:,optLV),'go');
        legend2=[legend2; 'Cross validation'];
    end
    if is_exist_test
        scatter(ytest,yhat_test(:,optLV),'bo');
        legend2=[legend2;'Prediction'];
    end
    plot([min(ycal) max(ycal)],[min(ycal) max(ycal)],'k-','LineWidth',2);
    axis([min(ycal)*0.95 1.05*max(ycal) min(ycal)*0.95 1.05*max(ycal)]);
    legend([legend2; 'y=x'],Location='northwest');legend boxoff;
    xlabel('Reference');ylabel('Prediction');  
end

result.optLV=optLV;
result.coef_all=coef;
result.yhat_cal_all=yhat_cal;
result.RMSEC_all=RMSEC;
result.Rc2_all=R;
result.yhat_cal=yhat_cal(:,optLV);
result.RMSEC=RMSEC(optLV);
result.Rc2=R(optLV);
result.error_cal = error_cal;
result.VIP = VIP;


if ~isnan(n_fold)
    result.yhat_cv_all=yhat_cv;
    result.RMSECV_all=RMSECV;
    result.R2cv_all=Rcv;
    result.yhat_cv=yhat_cv(:,optLV); 
    result.RMSECV=RMSECV(optLV);
    result.R2cv=Rcv(optLV);
    result.error_cv = error_cv;
    result.SD=SD;
    result.RPD=RPD;
end

if is_exist_test
    result.yhat_test_all=yhat_test;
    result.RMSEP_all=RMSEP;
    result.R2p_all=Rp;
    result.yhat_test=yhat_test(:,optLV);
    result.RMSEP=RMSEP(optLV);
    result.R2p=Rp(optLV);
    result.error_test = error_test;

end
end

function [RMSEC,R2]=calc_rmsec(y,yhat)
% input y        m*1   The ture value of chemical response
%       yhat     m*A The prediction of PLS model with 1:A factors.
[m,A]=size(yhat);
Err=yhat-y*ones(1,A);
sqrE=Err.^2;
meansqrE=mean(sqrE,1);
RMSEC=sqrt(meansqrE);
R2=(corr(y,yhat)).^2;
end
