function h1=plotVerticalBar( wav,spec,sel,lab )
%PLOTVERTICALBAR Summary of this function goes here
%   Detailed explanation goes here
h1=figure;%画出校正集合
h=plot(wav,spec(1,:),'k-','LineWidth',1.5);hold on;
max_s=max(spec(1,:));
min_s=min(spec(1,:));
inter_val=0.1*(max_s-min_s);
start=min_s;
color=hsv(length(sel));
hh=[h];
for i=1:length(sel)
    start=start-2*inter_val;
    sel_i=wav(sel{i});x=repmat(sel_i(:)',2,1);
    y=[repmat(start,1,size(sel_i,2));repmat(start-inter_val,1,size(sel_i,2))];
    h_tmp=line(x,y,'Color',color(i,:),'LineWidth',1);
    hh=[hh h_tmp(1)];
end
legend(hh,lab);
legend('boxoff') 
xlim([min(wav) max(wav)]);
xlabel('Wavelength (nm)');ylabel('Intensity (A.U.)');
set(gca, 'Fontname', 'Times New Roman','FontSize',18,'LineWidth',1.5);
end

