function [ pvalue ] = random_T_Test( yhatA,yhatB,y,niter )
%RANDOM_T_TEST 此处显示有关此函数的摘要
%   此处显示详细说明
if nargin<4;niter  = 199;end

eA= y(:)'- yhatA(:)';
eB= y(:)'- yhatB(:)';
diff=eA.^2-eB.^2;
meandiff=mean(diff);
n=length(diff);

sum= 0;
for k = 1: niter
    randomsign=2*round(rand(1,n))-1;
    signeddiff  =randomsign.*diff;
    meansigneddiff=mean(signeddiff);
    sum=sum+(abs(meansigneddiff)>=abs(meandiff));
end
pvalue=(sum+1)/(niter+1);
end

