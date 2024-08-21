%#Standard Normal Variate Transformation			
%#		Row centering, followed by row scaling.			
%#									
%#  PRINCIPLE:  Removal of the row mean from each row, followed 	
%#              by division of the row by the respective row	 	
%#		standard deviation.		 		 	
%# 									
%#  INPUT:	x: (m x n) matrix with m spectra and n variables	
%#			 						
%#  OUTPUT:	xsnv: (m x n) matrix containing snv transformed spectra	
									
function [xsnv,meanx,stdd,xtsnv]=snv2(x,xt)
meanx=mean(x');
stdd=std(x');
[m,n]=size(x);
xsnv=(x-mean(x')'*ones(1,n))./(std(x')'*ones(1,n));

xtsnv=(xt-mean(xt')'*ones(1,n))./(std(xt')'*ones(1,n));