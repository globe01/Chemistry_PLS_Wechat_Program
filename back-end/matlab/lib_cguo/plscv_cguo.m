function CV=plscv_cguo(X,y,A,K)
%+++ K-fold Cross-validation for PLS
%+++ Input:  X: m x n  (Sample matrix)
%            y: m x 1  (measured property)
%            A: The maximal number of latent variables for cross-validation
%            K: fold. when K=m, it is leave-one-out CV
%+++ Output: Structural data: CV
%  This program is based on the function in libpls 1.95 and do some
%  accelation. So, the y must be a vactor with only one colum.
if nargin<4;K=10;end
if nargin<3;A=3;end

[Mx,Nx]=size(X);
A=min([size(X) A]);
YR=nan(Mx,A);

groups = 1+rem(0:Mx-1,K);
% cv=NaN(K,A);
for group=1:K
    calk = find(groups~=group);
    testk = find(groups==group);
    
    Xcal=X(calk,:);
    ycal=y(calk);
    Xtest=X(testk,:);
    
    %   data pretreatment
    [Xs,xpara1,xpara2]=pretreat(Xcal,'center');
    [ys,ypara1,ypara2]=pretreat(ycal,'center');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [B]=simpls(Xs,ys,A);   % no pretreatment.
    
    %+++ calculate the coefficient linking Xcal and ycal.
    C=ypara2*B./xpara2';
    coef=[C;ypara1-xpara1*C;];
    %+++ predict
    Xteste=[Xtest ones(size(Xtest,1),1)];
    YR(testk,:)=Xteste*coef;
%     err=YR(testk,:)-y(testk)*ones(1,A);
%     if length(testk)==1
%         cv(group,:)= sqrt((err.^2));
%     else
%         cv(group,:)= sqrt(mean(err.^2));
%     end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% mean and sd of squared error %%%%%%%%%%%%
error=YR-repmat(y,1,A);
cv=sqrt(mean(error.^2));
[RMSEP,index]=min(cv);index=min(index);
SST=sumsqr(y-mean(y));
Q2=NaN(A,1);
for i=1:A
    SSE=sumsqr(YR(:,i)-y);
    Q2(i)=1-SSE/SST;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%+++ output  %%%%%%%%%%%%%%%%
CV.ypred=YR;
CV.error=error;
CV.RMSECV=cv;
CV.Q2=Q2;
CV.RMSECV_min=RMSEP;
CV.Q2_max=Q2(index);
CV.optLV=index;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





