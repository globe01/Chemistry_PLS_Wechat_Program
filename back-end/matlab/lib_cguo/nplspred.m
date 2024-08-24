function [ ypred,RMSEP,R ] = nplspred( X,y,Fac,Xfactors,Yfactors,Core,B )
%NPLSPRED Summary of this function goes here
%   Detailed explanation goes here
%   ¶ÔnplsµÄ²¹³ä:[ypred,T,ssX,Xres]=npred(X,Fac,Xfactors,Yfactors,Core,B,show)
%   The base libary is Nway-Toolbox 3.3
%   Zhang Jin 2017.8.29 zhangjin@mail.nankai.edu.cn
[ypred]=npred(X,Fac,Xfactors,Yfactors,Core,B,NaN);
RMSEP=sqrt(mean((ypred-y).^2));
R=corr(ypred,y);
end

