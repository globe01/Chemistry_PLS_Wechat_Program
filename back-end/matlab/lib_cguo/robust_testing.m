function [ result ] = robust_testing( Xcal,ycal,Xtest,ytest,vsel,nLV,n_mc,method )
%ROBUST_TESTING Summary of this function goes here
%   Detailed explanation goes here
Xcal=Xcal(:,vsel);
Xtest=Xtest(:,vsel);
ratio=0.8;
[row_c,col_c]=size(Xcal);
[row_v,col_v]=size(Xtest);
y_pred =zeros(row_v,n_mc);
RMSEP =zeros(n_mc,1);
R     =zeros(n_mc,1);
for i=1:n_mc
    rnd_idx=randperm(row_c,fix(row_c*ratio));
    PLS=pls( Xcal(rnd_idx,:),ycal(rnd_idx),nLV,method);
    [y_pred(:,i),RMSEP(i),R(i)]=plsval(PLS,Xtest,ytest,nLV);
    if mod(i,100)==0;disp(['第 ',num2str(i),' 次稳定性测试'])
end
result.y_pred=y_pred;
result.RMSEP=RMSEP;
result.R=R;
end

