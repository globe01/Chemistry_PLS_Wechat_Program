function [Xcal,Xtest,ycal,ytest] = ky(X,y,ratio)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% ratio 3, 4, ...
[y,idx]=sort(y);
X=X(idx,:);
Xtest=X(2:ratio:end-1,:);ytest=y(2:ratio:end-1,:);
X(2:ratio:end-1,:)=[];y(2:ratio:end-1,:)=[];
Xcal=X;ycal=y;

end

