%fig_Y_pred(cal_y,cvpredpls(:,:,LVs),'C')
% set(gcf,'Position',[100 100 340 300]);
set(gcf,'Position',[100 100 240 200]);

figure_FontSize=10;
% set(get(gca,'XLabel'),'FontSize',figure_FontSize,'Vertical','top','FontName','Times New Roman');
% set(get(gca,'YLabel'),'FontSize',figure_FontSize,'Vertical','middle','FontName','Times New Roman');
set(gca,'FontSize',figure_FontSize,'FontName','Arial');
set(findobj('FontSize',figure_FontSize),'FontSize',figure_FontSize,'FontName','Times New Roman');

clear figure_FontSize