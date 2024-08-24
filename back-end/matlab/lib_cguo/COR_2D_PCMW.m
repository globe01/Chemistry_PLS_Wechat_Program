function [sync,async] = COR_2D_PCMW(T,data,half_window)
% COR_2D_PCMW 此处显示有关此函数的摘要
% Ref: Perturbation-Correlation Moving-Window Two-Dimensional Correlation Spectroscopy
% chinnzhang@gmail.com
[row,col]=size(data);
T=T(:);
[n,m] = size(data);
sync=zeros(n-2*half_window,m);
async=zeros(n-2*half_window,m);
noda=NODA(T);
for i=1+half_window:n-half_window
    band=i-half_window:i+half_window;
    Pj=T-mean(T(band));
    sync(i-half_window,:) = sum(data(band,:).*(Pj(band)*ones(1,col)))/(2*half_window);
    async(i-half_window,:) = sum(data(band,:).*(noda(band,i).*Pj(band)*ones(1,col)))/(2*half_window);
end
end
function noda=NODA(T)
[n] = length(T);
noda  = zeros(n,n);
t0 = 2*T(1)-T(2);
tend = 2*T(end)-T(end-1);
T_expand = [t0;T(:);tend];
%% noda矩阵计算
for i=1:n
    for j=1:n
        if i~=j
            noda(i,j) = (T_expand(j+2)-T_expand(j))/(2*pi)/(T_expand(j+1)-T_expand(i+1));  %noda矩阵的求算公式
        end
    end
end
end
