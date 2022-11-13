%% 本程序用于自动提取CE4光谱数据
%请在使用前将月昼数据的文件夹名称改为‘DayXX’的格式，以便程序自动提取月昼参数
%使用前需要更改三个路径参数
%本程序需要函数extr_SD2BL_par；extr_VD2BL_par
%无校正矩阵校正
restoredefaultpath
clear
close all
addpath 'G:\code\GA-PLSR-CE4' %本程序以及所需函数所在路径
addpath 'G:\code\CE-data' %附加数据所在路径
load CE4_VNIS_par.mat %载入CMOS中SWIR区域的id，VNIS波长，对太阳光谱的响应等参数
Sun_Moon_Dista=readtable('Sun_Moon_Distance.xlsx'); %读取日月距离
filePath='J:\CE4-data\Day42\VNIS'; %数据文件所在路径
Par_VD_allfile=table();
Par_SD_allfile=table();
Ref_Day_all=table();
%可以控制day_0和day_end，选择需要反演的光谱Day的范围，也可以设置为其中的某一天
day_0=42;
day_end=42;
for day_file_n=day_0:day_end
output_path='J:\CE4-VNIS-exported';
filePath(16:17)=num2str(day_file_n); %数据文件所在路径
cd(filePath);
dir_VD2BL=dir(fullfile(filePath,'*VD*.2BL'));%CMOS File CE4_GRAS_VNIS-VD*.2C
file_VD2BL={dir_VD2BL.name}';
file_VD2BL=cell2mat(file_VD2BL);   % convert cell to matrix.
fileNum = size(file_VD2BL,1); % count the total number of files.
Par_VD_all=table();
Par_SD_all=table();
Day_name=char(regexp(filePath,'Day+\d+\','match'));%利用正则表达式匹配文件夹名称中的月昼编号，\d表示任意数字
Day_name=Day_name(1:end-1);
Day_num=str2double(Day_name(4:end));
if Day_num<7
    warning('第七月昼之前的数据需要乘以校正系数!!!');
end
% SWIR_scale=[128,98,53.8];%SWIR区域在COMS中的中心点位置和半径,单位pixel
CMOS_show_band=560;%artifacts在620-690(Unclear),750-900(FR46高分子材料吸收，弱光照情况下影响更大)
sbp=[4,1];%是subplot的行数和列数
VNIS_WL=[CMOS_WL(1:end-5)';SWIR_WL(6:end)'];
VNIS_WL=array2table(VNIS_WL);
VNIS_WL.Properties.VariableNames={'WL/nm'};
Ref_Day_x=VNIS_WL;%存储反射率结果的表格
for i=1:fileNum
    %% 读取2BL头文件参数
    %测量过程中，CMOS和SWIR的太阳高度角存在略微差异;还需提取日月距离参数
    filename_VD2BL=file_VD2BL(i,:);
    disp(filename_VD2BL(1:end-4));
    [Par_VD_i]=extr_VD2BL_par(filename_VD2BL);%从CMOS VD2BL头文件提取参数
    Sol_inc_CMOS=Par_VD_i.solar_ang(1);%提取CMOS太阳入射角参数
    Par_VD_all=[Par_VD_all;Par_VD_i];
    filename_SD2BL=filename_VD2BL;
    filename_SD2BL(15)='S';
    [Par_SD_i]=extr_SD2BL_par(filename_SD2BL);%从SWIR SD2BL头文件提取参数
    Sol_inc_SWIR=Par_VD_i.solar_ang(1);%提取SWIR太阳入射角参数
    Par_SD_all=[Par_SD_all;Par_SD_i];
    Sol_rad_CMOS=J_Sol_CMOS*cosd(Sol_inc_CMOS)/pi;%入射光,这里是否应该用Sol_inc_SWIR？
    Sol_rad_SWIR=J_Sol_SWIR*cosd(Sol_inc_SWIR)/pi;%入射光
    %% 读取CMOS和SWIR数据
    %读取CMOS数据，提取重合区域光谱
    filename_VD2B=filename_SD2BL(1:end-1);
    filename_VD2B(15)='V';
    fID_CMOS = fopen(filename_VD2B);
    CMOS_sor = fread(fID_CMOS,'float')';
    fclose(fID_CMOS);
    CMOS_sor=reshape(CMOS_sor,[65536,100]);
    CMOS_i=reshape(CMOS_sor,[256,256,100]);
    CMOS_i=permute(CMOS_i,[2 1 3]);%转置第一个和第二个维度  
    CMOS_rad=mean(CMOS_sor(SWIR_ind_logi,:));
    %读取SWIR数据
    filename_SD2B=filename_SD2BL(1:end-1);
    Dat_SD_all = readtable(filename_SD2B,'FileType','text');
    Dat_SD_all.Properties.VariableNames={'Time','Band','Expo','Sol_Eleva','Radi','Qual'};
    SWIR_rad=(Dat_SD_all.Radi)';
    %% 查找日月距离
    %需要计算开始和结束的中间时间，或者取SWIR中间位置的时间(简单快速)
    Time_i=cell2mat(Dat_SD_all.Time(150));%取中间位置的时间
    Time_date=Time_i(1:10);
    Time_H=str2double(Time_i(12:13));
    Time_M=str2double(Time_i(15:16));
    Date_id=find(strcmp(Sun_Moon_Dista.Date,Time_date));%查找日期id
    Hour_id=find(Sun_Moon_Dista.Hour(Date_id)==Time_H);
    Dista_scale=Sun_Moon_Dista.Sun_Moon_Distance([Date_id(Hour_id),Date_id(Hour_id)+1]);
    Dinta_i=(Dista_scale(2)-Dista_scale(1))*(Time_M/60)+Dista_scale(1);%线性插值计算精确距离,1AU  
    %% 计算反射率并消除gap 900~945是gap1重合波长，gap2位于1375和1380之间 
    Ref_CMOS_0=CMOS_rad./Sol_rad_CMOS*(Dinta_i^2);
    Ref_SWIR_0=SWIR_rad./Sol_rad_SWIR*(Dinta_i^2);
    if Day_num<7
        disp('------Day num less than 7, calibration matrix was used!!!!')
        Ref_CMOS_0=Ref_CMOS_0.*CMOS_cali';
        Ref_SWIR_0=Ref_SWIR_0.*SWIR_cali';
    end
    id_1380=find((SWIR_WL-1380)==0);
    id_1375=find((SWIR_WL-1375)==0);
    gap2_1380=Ref_SWIR_0(id_1380);
    gap2_1375=Ref_SWIR_0(id_1375);
    Ref_SWIR_1=Ref_SWIR_0;
    if gap2_1380-gap2_1375 > (Ref_SWIR_0(id_1380+1)-gap2_1380)*2 %检测gap2是否存在，如果存在则消去
        Ref_SWIR_1(1:id_1375)=Ref_SWIR_0(1:id_1375)*(gap2_1380/gap2_1375);%消除gap2
    else
        disp('---There is no 1375-1380 gap in this spectrum.---');
    end
    gap1_CMOS=Ref_CMOS_0(end-9);%mean(Ref_CMOS_0(end-7:end))
    gap1_SWIR=Ref_SWIR_1(1);%mean(Ref_SWIR_1(3:10));
    Ref_CMOS_1=Ref_CMOS_0*(gap1_SWIR/gap1_CMOS);%消除gap1
    %% 保存数据
    Spec_i=[Ref_CMOS_1(1:end-10)';Ref_SWIR_1'];%将CMOS和SWIR拼接在一起
    Spec_i=array2table(Spec_i);
    Img_Name=['N',num2str(Par_SD_i.sequence_id(1)),'-D',Day_name(4:end)];
    Spec_i.Properties.VariableNames={Img_Name};
    Ref_Day_x=[Ref_Day_x,Spec_i];
    %% 绘图
    figure();
    subplot(sbp(1),sbp(2),1);%展示CMOS图像
    imagesc(CMOS_i(:,:,find((CMOS_WL-CMOS_show_band)==0)));
    title([Img_Name,'_Rad_',num2str(CMOS_show_band),'nm'],'Interpreter','none');
    colormap gray
    hold on
    rectangle('Position',[98-53.8 256-128-53.8 53.8*2 53.8*2],'Curvature',[1 1],'EdgeColor','yellow','LineWidth',0.8);%绘制SWIR的重合区域
    scatter(98,256-128,128,'red','+','LineWidth',1.5);
    axis equal%坐标轴等距
    axis tight
    axis off %不显示坐标轴
    text(280,20,['Time: ',Time_i(1:16)]);
    text(280,70,['Sun-Moon-Dis: ',num2str(Dinta_i,'%1.6f'),'AU']);
    text(280,120,['Sol-Inc: ',num2str(Sol_inc_SWIR,'%2.1f'),'°']);
    set(gcf, 'Color', 'w');
    subplot(sbp(1),sbp(2),2);%绘制radi数据
    plot(CMOS_WL,CMOS_rad,'Color',[0,0.5,0.8]);
    hold on
    plot(SWIR_WL,SWIR_rad,'Color',[0.8,0.5,0]);
    plot(CMOS_WL,Sol_rad_CMOS/10,'Color','blue','Marker','o','MarkerIndices',1:40:length(Sol_rad_CMOS));
    plot(SWIR_WL,Sol_rad_SWIR/10,'Color','red','Marker','o','MarkerIndices',30:40:length(Sol_rad_SWIR));
    axis padded
    set(gca,'XLim',[400,2450],'XMinorTick','on','YScale','log')
    ax=gca;
    ax.YLabel.String='Rad.';
    legend('Samp_CMOS_rad','Samp_SWIR_rad','Sol_CMOS_rad/10','Sol_SWIR_rad/10','Interpreter','none');
    subplot(sbp(1),sbp(2),3);%绘制ref数据
    plot(CMOS_WL,Ref_CMOS_0,'LineWidth',1);
    hold on
    plot(SWIR_WL,Ref_SWIR_0,'LineWidth',1);
    axis padded
    set(gca,'XLim',[400,2450],'XMinorTick','on')
    ax=gca;
    ax.YLabel.String='Ref.';
    legend('CMOS','SWIR','Location','southeast');
    subplot(sbp(1),sbp(2),4);%绘制消除gap后的ref数据。900~945是重合波长
    plot(CMOS_WL,Ref_CMOS_1,'LineWidth',1);
    hold on
    plot(SWIR_WL,Ref_SWIR_1,'LineWidth',1);
    axis padded
    set(gca,'XLim',[400,2450],'XMinorTick','on')
    ax=gca;
    ax.XLabel.String='Wavelength (nm)';
    ax.YLabel.String='Ref.';
    legend('CMOS(Scale 900 to SWIR)','SWIR(Scale 1375 to 1380)','Location','southeast','Interpreter','none');
    set(gcf,'Position',[500,115,1000,900]);
    img_file_name=[Img_Name,'.jpg'];
    exportgraphics(gcf,img_file_name,'Resolution',500)
    copyfile(img_file_name,output_path);
end
%将提取的数据写入xlsx文件
writetable(Par_VD_all,[Day_name,'_Par_VD.xlsx']);
writetable(Par_SD_all,[Day_name,'_Par_SD.xlsx']);
writetable(Ref_Day_x,[Day_name,'_Ref.xlsx']);
%将文件复制到汇总的文件夹
copyfile([Day_name,'_Par_VD.xlsx'],output_path);
copyfile([Day_name,'_Par_SD.xlsx'],output_path);
copyfile([Day_name,'_Ref.xlsx'],output_path);
Par_VD_allfile=[Par_VD_allfile;Par_VD_all];
Par_SD_allfile=[Par_SD_allfile;Par_SD_all];
Ref_Day_all(:,1)=Ref_Day_x(:,1);
Ref_Day_all=[Ref_Day_all,Ref_Day_x(:,2:end)];
end
%%
cd(output_path)
%将所有数据汇总到同一个表格
writetable(Par_VD_allfile,['Par_VD_Day',num2str(day_0),'-',num2str(day_end),'.xlsx']);
writetable(Par_SD_allfile,['Par_SD_Day',num2str(day_0),'-',num2str(day_end),'.xlsx']);
writetable(Ref_Day_all,['Par_Ref_Day',num2str(day_0),'-',num2str(day_end),'.xlsx']);
restoredefaultpath


% CMOS_ant_sele=CMOS_sor(:,CMOS_show_band);
% CMOS_ant_sele(SWIR_ind_logi)=0;
% CMOS_ant_sele=reshape(CMOS_ant_sele,[256,256])';
% imagesc(CMOS_ant_sele,'AlphaData',0.6)
% images.roi.Circle(gca,'Center',[98 256-128],'Radius',53.8);

% system('rename *SD*.2B *.txt');%将SD/SWIR.2B文件更改后缀为txt，以便以readtable方法快速读取数据
% system('rename *SD*.txt *.2B');%将更改的文件后缀还原
%     [time, bands, exposure, ang, radi, qua] = textread(filename_SD2B,'%24s %2d %f %s %f %f');%会多读取空格为0值进来