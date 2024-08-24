function [ Xcal,Xtest ] = data_preprocess( Xcal,ycal,Xtest,flag,rank_uve )
%DATA_PREPROCESS Summary of this function goes here
%   Detailed explanation goes here
if nargin<5
    rank_uve=10;
end
switch flag
    case 'none'
    case 'uve'
        [ var_selected_uve ] = UVE( Xcal-mean(Xcal),ycal(:),1e-15,rank_uve );
        Xcal                 = Xcal(:,var_selected_uve);
        Xtest                = Xtest(:,var_selected_uve);
        
    case 'msc'
        [Xcal,me,Xtest]=msc(Xcal,1,size(Xcal,2),Xtest);
    case 'snv'
        Xcal   = snv(Xcal);
        Xtest  = snv(Xtest);
    case 'cwt1'
        Xcal     = wavederive(Xcal,'haar',20);
        Xtest    = wavederive(Xtest,'haar',20);
    case 'cwt2'
        Xcal     = wavederive(Xcal,'sym2',20);
        Xtest    = wavederive(Xtest,'sym2',20);
    case 'cwt1_uve'
        Xcal     = wavederive(Xcal,'haar',20);
        Xtest    = wavederive(Xtest,'haar',20);
        
        [ var_selected_uve ] = UVE( Xcal-mean(Xcal),ycal(:),1e-15,rank_uve );
        Xcal                   = Xcal(:,var_selected_uve);
        Xtest                     = Xtest(:,var_selected_uve);
    case 'cwt2_uve'
        Xcal     = wavederive(Xcal,'sym2',20);
        Xtest    = wavederive(Xtest,'sym2',20);
        
        [ var_selected_uve ] = UVE( Xcal-mean(Xcal),ycal(:),1e-15,rank_uve );
        Xcal                   = Xcal(:,var_selected_uve);
        Xtest                  = Xtest(:,var_selected_uve);
    case 'msc_cwt1'
        [Xcal,me,Xtest]=msc(Xcal,1,size(Xcal,2),Xtest);
        
        Xcal     = wavederive(Xcal,'haar',20);
        Xtest    = wavederive(Xtest,'haar',20);
        
    case 'snv_cwt1'
        Xcal_snv=snv(Xcal);
        Xtest_snv=snv(Xtest);
        
        
        Xcal     = wavederive(Xcal,'haar',20);
        Xtest    = wavederive(Xtest,'haar',20);
    case 'msc_cwt1_uve'
        [Xcal,me,Xtest]=msc(Xcal,1,size(Xcal,2),Xtest);
        
        Xcal     = wavederive(Xcal,'haar',20);
        Xtest    = wavederive(Xtest,'haar',20);
        
        [ var_selected_uve ] = UVE( Xcal-mean(Xcal),ycal(:),1e-15,rank_uve );
        Xcal                  = Xcal(:,var_selected_uve);
        Xtest                 = Xtest(:,var_selected_uve);
        
    otherwise
        disp('the input parameters is rong');
end
end

