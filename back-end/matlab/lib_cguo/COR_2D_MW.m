function [ sync,async ] = COR_2D_MW( T,data,half_window )
%MW_2DCOR2 此处显示有关此函数的摘要
%   此处显示详细说明
%   reference:
%   Perturbation-Correlation Moving-Window Two-Dimensional Correlation Spectroscopy
%   Moving-Window Two-Dimensional Correlation Spectroscopy Based on a Slice Spectrum. 
[n,m] = size(data);
sync=zeros(n-2*half_window,m);
async=zeros(n-2*half_window,m);
for i=1+half_window:n-half_window
    [temp1,temp2] = COR_2D(T(i-half_window:i+half_window),data(i-half_window:i+half_window,:));
    sync(i-half_window,:) = temp1(2,:);
    async(i-half_window,:)=temp2(2,:);
end
end

