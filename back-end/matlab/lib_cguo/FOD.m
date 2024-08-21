function [ idx,D,L,C ] = FOD( x,ng,isplot )
%   Fisher optimal partitions(FOD)
%   Reference:
%   1.	Lin, Y.-W. et al,  Chemom. Intell. Lab. Syst. 2016, 159, 196-204.
%   2.  Leigh J. Fitzgibbon, et al. Minimum Message Length Grouping of Ordered Data
%   3.  http://wiki.objectvision.nl/index.php/Fisher%27s_Natural_Breaks_Classification
%   4.  https://github.com/road2stat/OHPL/blob/master/R/FOP.R
%   Writed by ZJ
%   chinnzhang@gmail.com
%   2017.9.13
% Input: x  input order
%        ng number of devision groups(clusters)
if nargin<3;isplot=false;end
x=x(:)';
lx=length(x);

D=NaN(lx,lx);
for i=1:lx
    for j=i:lx
        D(i,j)=sum(((x(i:j)-mean(x(i:j))).^2));
        %         if i~=j;D(j,i)=D(i,j);end
    end
end

L=NaN(lx-1,ng-1);
C=NaN(lx-1,ng-1);
%计算二分问题
for i=2:lx
    tmp=NaN(lx,1);
    for j=2:i
        tmp(j)=D(1,j-1)+D(j,i);
    end
    [L(i-1,1),C(i-1,1)]=min(tmp);
end
%C(:,1)=C(:,1)+1;
%根据二分问题的结果计算多分问题
for LL=3:ng%L
    for II=LL:lx%I
        tmp=NaN(lx,1);
        for JJ=LL:II%J
            tmp(JJ)=L(JJ-2,LL-2)+D(JJ,II);
        end
        [L(II-1,LL-1),C(II-1,LL-1)]=min(tmp);
    end
end

idx=ones(1,lx);
if ng>1
    breaks=zeros(1,ng);
    breaks(1)=1;
    breaks(ng)=C(lx-1,ng-1);
    idx(breaks(ng):lx)=ng;
    for flag=ng-1:-1:2
        breaks(flag)=C(breaks(flag+1)-2,flag-1);
        idx(breaks(flag):breaks(flag+1)-1)=flag;
    end
end

if isplot
    figure;hold on;
    for i=1:ng
        idx_plot=find(idx==i);
        plot(idx_plot,x(idx_plot),'*','color',rand(1,3));
    end
    hold off;
end
end

