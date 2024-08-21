%% 波长选择方法之RT方法，即随机检验
function [result]=rtpls(cal, caltar, nLV,n_mc, selectLV)  %其中cal是校正集即建模集，caltar是校正集对应的浓度，runtimes是迭代次数，一般选择500，
%factor是选择的因子数，一般是留一交叉法LOOV求得，或是靠尝试

method='center';
n_fold=5;
order=0;

tic

[num,col]=size(cal);
cal=cal-mean(cal);
caltar=caltar-mean(caltar);


B = simpls(cal, caltar, nLV);
coef0 = B(:,end);

for i=1:n_mc
    rlist = randperm(num);
    y2 = caltar(rlist);
    B = simpls(cal, y2, nLV);
    coefs(i,:) = B(:,end)';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[a,b] = size(coefs);  P=[];
for i = 1:length(coef0)
    noisev = coef0(i);
    row = find(abs(coefs(:,i))>=abs(noisev));
    k = length(row);
    per = k/a;
    P = [P,per];
end

[~,index] = sort(P);  %此时pp就是按照降序排列的，然而index就是对应的波长点，wvleng中的波长点

%+++  Cross-Validation to choose an optimal subset;
RMSECV=zeros(1,col);
Q2_max=zeros(1,col);
LV=zeros(1,col);
for i=1:col
    vsel=index(1:i);
    
    CV=plscv(cal(:,vsel),caltar,nLV,n_fold,method,0,order);
    if selectLV == 0
        RMSECV(i)=CV.RMSECV_min;
        Q2_max(i)=CV.Q2_max;
        LV(i)=CV.optLV;
    elseif selectLV==1
        RMSECV(i)=CV.RMSECV_min_1SD;
        Q2_max(i)=CV.Q2_max_1SD;
        LV(i)=CV.optLV_1SD;
    end
    if mod(i,100)==0
        fprintf('The %d/%dth variable validation finished.\n',i,col);
    end
end
[RMSECV_min,indexOPT]=min(RMSECV);
Q2_max=max(Q2_max);


%+++ save results;
time=toc;
%+++ output
result.P_value=P;
result.time=time;
result.RMSECV=RMSECV;
result.RMSECV_min=RMSECV_min;
result.Q2_max=Q2_max;
result.iterOPT=indexOPT;
result.optLV=LV(indexOPT);
result.vsel=index(1:indexOPT);
end


%最后就是看P的大小，但是P不是按照顺序排序的，需要将P进行降序排列
% [pp,index] = sort(P,'descend');  %此时pp就是按照降序排列的，然而index就是对应的波长点，wvleng中的波长点
% ind = index(1:220);   %一般选择总波长的10%到20%，不要超过20%。一共2205个波长点，所以这里选择了220个
% sp = data.sp(:,ind);  %这就是最终选择的波长点