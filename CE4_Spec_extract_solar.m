%% This program calaulate the CE-4 REFF spectra based on solar irradiance method
% The CE-4 VNIS spectral data can be downloaded from the official website: https://moon.bao.ac.cn/ce5web/searchOrder_dataSearchData.search
% Specify the "outpu_path", "file_path" and "code_path" before running
% Specify the "day_start" and "day_end"before using
% Date: Apr.2022
% Author: Zhenxing Zhao, China, Beijing, NSSC, Chinese Academy of Sciecnes
% (2020-2025)
% If you have any questions, please contact cooperzhaozx@gmail.com
% My website (Chinese): cooperzzx.com
% Solar irradiance method: Yang et al., 2020. The Effects of Viewing Geometry on the Spectral Analysis of Lunar Regolith as Inferred by in situ Spectrophotometric Measurements of Chang'E‐4
%% init
%Please rename the data folder in the format: 'DayXX', so that the program can automatically extracts the lunar day number
%Specify these three path: file_path, output_path, code_path
%This program needs the following additional functions: 'extr_SD2BL_par'; 'extr_VD2BL_par'
%This program needs the following additional data: 'CE4_VNIS_par.mat'; 'Sun_Moon_Distance.xlsx'
restoredefaultpath
clear
close all
code_path='*';%The path of addtional functions and data
file_path='J:\CE4-data\Day01\VNIS'; %the file path of the VNIS data
output_path='J:\CE4-VNIS-exported';
addpath(code_path);
load CE4_VNIS_par.mat %Load the index of SWIR in CMOS, CE-4 wavelength, the response of VNIS to solar irradiance
Sun_Moon_Dista=readtable('Sun_Moon_Distance.xlsx');
%Specify the start and stop of the time (lunar day) that CE-4 collect VNIS data
day_start=1;
day_end=59;
%% program start
for day_file_n=day_start:day_end
    if day_file_n<10
        file_path(16:17)=['0',num2str(day_file_n)]; % When Day<10
    else
        file_path(16:17)=num2str(day_file_n); % Folder of the VNIS data
    end
    cd(file_path);
    dir_VD2BL=dir(fullfile(file_path,'*VD*.2BL')); % CMOS File CE4_GRAS_VNIS-VD*.2C
    file_VD2BL={dir_VD2BL.name}';
    file_VD2BL=cell2mat(file_VD2BL);   % convert cell to matrix.
    fileNum = size(file_VD2BL,1); % count the total number of files.
    Par_VD_all=table();
    Par_SD_all=table();
    Par_VD_allfile=table();
    Par_SD_allfile=table();
    Ref_Day_all=table();
    Day_name=char(regexp(file_path,'Day+\d+\','match'));% Match the lunar day number using regular expression
    Day_name=Day_name(1:end-1);
    CMOS_show_band=560;
    sbp=[4,1]; % row and col of the subplots
    VNIS_WL=[CMOS_WL(1:end-5)';SWIR_WL(6:end)'];
    VNIS_WL=array2table(VNIS_WL);
    VNIS_WL.Properties.VariableNames={'WL/nm'};
    Ref_Day_x=VNIS_WL; %table to store the REFF data
    for i=1:fileNum
       %% read the .2BL headers
        % The solar incidence angle of CMOS channel detection is slightly different from that of SWIR channel
        filename_VD2BL=file_VD2BL(i,:);
        disp(filename_VD2BL(1:end-4));
        [Par_VD_i]=extr_VD2BL_par(filename_VD2BL); % read the .2BL headers of CMOS in detection mode
        Sol_inc_CMOS=Par_VD_i.solar_ang(1); % read the solar incidence angle of CMOS
        Par_VD_all=[Par_VD_all;Par_VD_i];
        filename_SD2BL=filename_VD2BL;
        filename_SD2BL(15)='S';
        [Par_SD_i]=extr_SD2BL_par(filename_SD2BL); % read the .2BL headers of SWIR in detection mode
        Sol_inc_SWIR=Par_VD_i.solar_ang(1); % read the solar incidence angle of SWIR
        Par_SD_all=[Par_SD_all;Par_SD_i];
        Sol_rad_CMOS=J_Sol_CMOS*cosd(Sol_inc_CMOS)/pi; % solar radicane
        Sol_rad_SWIR=J_Sol_SWIR*cosd(Sol_inc_SWIR)/pi; % solar radicane
        %% read the raw CMOS and SWIR data
        % read CMOS data, extract the data of the SWIR detection region
        filename_VD2B=filename_SD2BL(1:end-1);
        filename_VD2B(15)='V';
        fID_CMOS = fopen(filename_VD2B);
        CMOS_sor = fread(fID_CMOS,'float')';
        fclose(fID_CMOS);
        CMOS_sor=reshape(CMOS_sor,[65536,100]);
        CMOS_i=reshape(CMOS_sor,[256,256,100]);
        CMOS_i=permute(CMOS_i,[2 1 3]);
        CMOS_rad=mean(CMOS_sor(SWIR_ind_logi,:));
        % read SWIR data
        filename_SD2B=filename_SD2BL(1:end-1);
        Dat_SD_all = readtable(filename_SD2B,'FileType','text');
        Dat_SD_all.Properties.VariableNames={'Time','Band','Expo','Sol_Eleva','Radi','Qual'};
        SWIR_rad=(Dat_SD_all.Radi)';
        %% find the distance between the Sun and the Moon
        % determine the time when the data was collected
        Time_i=cell2mat(Dat_SD_all.Time(150)); % take the time in the middle of the measurement
        Time_date=Time_i(1:10);
        Time_H=str2double(Time_i(12:13));
        Time_M=str2double(Time_i(15:16));
        Date_id=find(strcmp(Sun_Moon_Dista.Date,Time_date));
        Hour_id=find(Sun_Moon_Dista.Hour(Date_id)==Time_H);
        Dista_scale=Sun_Moon_Dista.Sun_Moon_Distance([Date_id(Hour_id),Date_id(Hour_id)+1]);
        Dinta_i=(Dista_scale(2)-Dista_scale(1))*(Time_M/60)+Dista_scale(1); % 1AU
        %% calculate the REFF and connect the REFF at two gaps (gap1: 900~945nm gap of CMOS and SWIR, gap2: 1375-1380 gap of SWIR
        Ref_CMOS_0=CMOS_rad./Sol_rad_CMOS*(Dinta_i^2);
        Ref_SWIR_0=SWIR_rad./Sol_rad_SWIR*(Dinta_i^2);
        id_1380=find((SWIR_WL-1380)==0);
        id_1375=find((SWIR_WL-1375)==0);
        gap2_1380=Ref_SWIR_0(id_1380);
        gap2_1375=Ref_SWIR_0(id_1375);
        Ref_SWIR_1=Ref_SWIR_0;
        if gap2_1380-gap2_1375 > (Ref_SWIR_0(id_1380+1)-gap2_1380)*2 % detect the presence of gap2 and eliminates it if it is present
            Ref_SWIR_1(1:id_1375)=Ref_SWIR_0(1:id_1375)*(gap2_1380/gap2_1375);
        else
            disp('---There is no 1375-1380 gap in this spectrum.---');
        end
        gap1_CMOS=Ref_CMOS_0(end-9);
        gap1_SWIR=Ref_SWIR_1(1);
        Ref_CMOS_1=Ref_CMOS_0*(gap1_SWIR/gap1_CMOS); % eliminate gap1
        %% save data
        Spec_i=[Ref_CMOS_1(1:end-10)';Ref_SWIR_1']; %joint CMOS and SWIR data
        Spec_i=array2table(Spec_i);
        Img_Name=['N',num2str(Par_SD_i.sequence_id(1)),'-D',Day_name(4:end)];
        Spec_i.Properties.VariableNames={Img_Name};
        Ref_Day_x=[Ref_Day_x,Spec_i];
        %% plots
        figure();
        subplot(sbp(1),sbp(2),1); % show CMOS image
        imagesc(CMOS_i(:,:,find((CMOS_WL-CMOS_show_band)==0)));
        title([Img_Name,'_Rad_',num2str(CMOS_show_band),'nm'],'Interpreter','none');
        colormap gray
        hold on
        rectangle('Position',[98-53.8 256-128-53.8 53.8*2 53.8*2],'Curvature',[1 1],'EdgeColor','yellow','LineWidth',0.8);%绘制SWIR的重合区域
        scatter(98,256-128,128,'red','+','LineWidth',1.5);
        axis equal
        axis tight
        axis off 
        text(280,20,['Time: ',Time_i(1:16)]);
        text(280,70,['Sun-Moon-Dis: ',num2str(Dinta_i,'%1.6f'),'AU']);
        text(280,120,['Sol-Inc: ',num2str(Sol_inc_SWIR,'%2.1f'),'°']);
        set(gcf, 'Color', 'w');
        subplot(sbp(1),sbp(2),2); % show radiance data
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
        subplot(sbp(1),sbp(2),3); % show the calculated REFF
        plot(CMOS_WL,Ref_CMOS_0,'LineWidth',1);
        hold on
        plot(SWIR_WL,Ref_SWIR_0,'LineWidth',1);
        axis padded
        set(gca,'XLim',[400,2450],'XMinorTick','on')
        ax=gca;
        ax.YLabel.String='Ref.';
        legend('CMOS','SWIR','Location','southeast');
        subplot(sbp(1),sbp(2),4);  % show the REFF after jointing the gaps
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
        close all
    end
    writetable(Par_VD_all,[Day_name,'_Par_VD.xlsx']);
    writetable(Par_SD_all,[Day_name,'_Par_SD.xlsx']);
    writetable(Ref_Day_x,[Day_name,'_Ref.xlsx']);

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
writetable(Par_VD_allfile,['Par_VD_Day',num2str(day_start),'-',num2str(day_end),'.xlsx']);
writetable(Par_SD_allfile,['Par_SD_Day',num2str(day_start),'-',num2str(day_end),'.xlsx']);
writetable(Ref_Day_all,['Par_Ref_Day',num2str(day_start),'-',num2str(day_end),'.xlsx']);
restoredefaultpath

