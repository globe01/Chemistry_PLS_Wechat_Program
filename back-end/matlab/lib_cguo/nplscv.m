function [ CV ] = nplscv( X,y,nLV,n_fold )
%NPLSCV Summary of this function goes here
%   Detailed explanation goes here
%   This func is the employment of cross validation of npls
%   The base libary is Nway-Toolbox 3.3
%   Zhang Jin 2017.8.29 zhangjin@mail.nankai.edu.cn

if nargin < 4; n_fold =10; end
if nargin < 5; nLV =10; end

DimX=size(X);
n_test=fix(DimX(1)/n_fold);

ypred = NaN(DimX(1), nLV);
rnd_idx=randperm(DimX(1));
for i=1:n_fold
    test_idx=rnd_idx((i-1)*n_test+1:i*n_test);
    cal_idx=setdiff(1:DimX(1),test_idx);
    Xcal=X(cal_idx,:,:);
    ycal=y(cal_idx);
    Xtest=X(test_idx,:,:);
    ytest=y(test_idx);
    [Xfactors,Yfactors,Core,B] = npls(Xcal,ycal,nLV,NaN);
    
    for j=1:nLV
        [ypred(test_idx,j)]=npred(Xtest,j,Xfactors,Yfactors,Core,B,NaN);
    end
    
    if mod(i,10)==0;disp(['第 ',num2str(i),' 次NPLS模型的交互验证']);end
end
Err=ypred-y;
RMSECV=sqrt(mean(Err.^2));
R=corr(ypred,y);
[RMSECV_min,optLV]=min(RMSECV);



CV.ypred=ypred;
CV.Err=Err;
CV.RMSECV=RMSECV;
CV.R=R;
CV.RMSECV_min=RMSECV_min;
CV.optLV=optLV;
end

