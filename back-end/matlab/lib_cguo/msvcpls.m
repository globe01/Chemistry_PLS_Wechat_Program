function [result]=msvcpls(X, y, nLV,n_fold,ng_v,n_sampling,is_orth)
% multi step variable selection based on C value.
% Jin Zhang
% zhangjin@mail.nankai.edu.cn
if nargin<7;is_orth=true;end %是否采样正交采样，true为采样正交采样，false为随机采样
if nargin<6;n_sampling=500;end   %sample为采样次数，为变量数的整数倍，默认为变量数的10倍
if nargin<5;ng_v=5;end
tic;

[~,col]=size(X);
sel=cell(0);
C_value=cell(0);
sel{1}=(1:col);
i_step=0;
vsel_i=sel{1};
while length(vsel_i)>max([25 2*nLV+5])
    i_step=i_step+1;
    
    vsel_i=sel{i_step,1};
    Xsel=X(:,vsel_i);
    ysel=y;
    sample_num_i=fix(n_sampling*length(vsel_i)/col);
    [C_tmp]=vcpls(Xsel, ysel, nLV, n_fold,sample_num_i,is_orth);
    C_value{i_step}=C_tmp;
    C_v=C_tmp(1:length(vsel_i));
    
    if i_step==1;isplot=true;else;isplot=false;end
    [sorted_C_v,idx_sorted_C_v]=sort(C_v);
    [ idx_v ] = FOD( sort(sorted_C_v),ng_v,isplot );
    v_outlier=idx_sorted_C_v(idx_v==ng_v);
    vsel_i=setdiff(sel{i_step,1},sel{i_step,1}(v_outlier));
    sel{i_step+1,1}=vsel_i;
    disp(['---MSVC---第 , ',num2str(i_step),' 步,剩余 ',num2str(length(vsel_i)),' 个变量']);
end
RMSECV=NaN(1,length(sel));
for i=1:length(sel)
    Xsel=X(:,sel{i,1});
    ysel=y;
    pred_tmpi=plspred_zj(Xsel,ysel,[],[],[],nLV,n_fold);%plspred_zj( Xsel,ysel,[],[],[],nLV,n_fold);
    RMSECV(i)=pred_tmpi.RMSECV;
end
[RMSECV_min]=min(RMSECV);
[min_row]=find(RMSECV==RMSECV_min);
min_row=min_row(1);
vsel=sel{min_row};

result.time=toc;
result.sel=sel;
result.C_value=C_value;
result.RMSECV=RMSECV;
result.RMSECV_min=RMSECV_min;
result.opt_vs_step=min_row;
result.vsel=vsel;
end

function C_value = vcpls(X, y, nLV,n_fold,n_sampling,is_orth)  %其中X是校正集即建模集，y是校正集对应的浓度，runtimes是迭代次数，一般选择500，
%factor是选择的因子数，一般是留一交叉法LOOV求得，或是靠尝试
tic
[~,col]=size(X);
sel_m=get_sampling_matrix(n_sampling,col,is_orth);
%-----------------C_value 估计------------------------------------
rmse=NaN(size(sel_m,1),1);
for i=1:size(sel_m,1)
    vsel=sel_m(i,:);
    Xsel= X(:,vsel);
    ysel=y;
    [ tmp_pred ] = plspred_zj( Xsel,ysel,[],[],[],nLV,NaN);
    rmse(i)=tmp_pred.RMSEC;
%     rmse(i) = rmse(i)^2;
end
sel_m_j=sel_m*1;
C_value=pinv(sel_m_j)*rmse;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%  采样矩阵生成  %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F=get_sampling_matrix(M,N,is_orth)
if is_orth
    n_rep=ceil(M/N);%进一发四舍五入
    sel_tmp=NaN(n_rep*N,N);
    for i=1:n_rep
        sel_tmp((i-1)*N+1:i*N,:)=orth(rand(N,N));
    end
    sel_tmp(M+1:end,:)=[];
else
    sel_tmp=rand(M,N);
end
sel_tmp=sel_tmp>(median(sel_tmp,2));
F=sel_tmp;
end
