%% This program calaulate the CE-4 REFF spectra based on solar irradiance method
% The CE-4 VNIS spectral data can be downloaded from the official website: https://moon.bao.ac.cn/ce5web/searchOrder_dataSearchData.search
% Date: Apr.2022
% Modefied data: Jul. 2024
% Author: Zhenxing Zhao, China, Beijing, NSSC, Chinese Academy of Sciecnes
% (2020-2025)
% If you have any questions, please contact cooperzhaozx@gmail.com
% My website (Chinese): www.cooperzzx.com
% Solar irradiance method: Yang et al., 2020. The Effects of Viewing Geometry on the Spectral Analysis of Lunar Regolith as Inferred by in situ Spectrophotometric Measurements of Chang'E‐4
%% init
%This program needs the following additional data: 'CE4_VNIS.mat'

restoredefaultpath
clear
close all
load CE4_VNIS.mat %Load the pixel index of SWIR in CMOS images, CE-4 wavelength, the response of CE-4 VNIS to the solar irradiance
Moon_Sun_Distance=1.0; %unit: AU. 1.014822 for CE-4 N136.The distance between the Sun and the Moon can be searched in https://ssd.jpl.nasa.gov/horizons/app.html#/.Simplfied to 1.0

disp('Specify the following variables before running the code');
Sol_inc_CMOS = 64.412 %unit deg. the incidence angle of the CMOS channel. 64,411 for CE-4 N136.can be found in the '.2BL' file of CMOS data.
Sol_inc_SWIR = 64.445 %unit deg. the incidence angle of the SWIR channel. 64.445 for CE-4 N136.can be found in the '.2BL' file of SWIR data.
CMOS_file_name = 'CE4_GRAS_VNIS-VD_SCI_N_20200716031001_20200716100000_0136_B.2B'
SWIR_file_name = 'CE4_GRAS_VNIS-SD_SCI_N_20200716031001_20200716100000_0136_B.2B'

%%

Sol_rad_CMOS=J_Sol_CMOS*cosd(Sol_inc_CMOS)/pi; % *cos(i): orthographic area, /pi: convert solar irradicane (w/m2) to radiance (w/m2/sr) based on ideal Lambertian body.
Sol_rad_SWIR=J_Sol_SWIR*cosd(Sol_inc_SWIR)/pi; % SWIR channel
%% read the raw CMOS and SWIR data
% read CMOS data, extract the data of the SWIR detection region
fID_CMOS = fopen(CMOS_file_name);
CMOS_orign = fread(fID_CMOS,'float')';
fclose(fID_CMOS);
CMOS_orign=reshape(CMOS_orign,[65536,100]);
CMOS_cube=reshape(CMOS_orign,[256,256,100]);
CMOS_cube=permute(CMOS_cube,[2 1 3]);
CMOS_rad=mean(CMOS_orign(SWIR_ind_logi,:));
% read SWIR data
Dat_SD_all = readtable(SWIR_file_name,'FileType','text');
Dat_SD_all.Properties.VariableNames={'Time','Band','Expo','Sol_Eleva','Radi','Qual'};
SWIR_rad=(Dat_SD_all.Radi)';

%% calculate the REFF and connect the REFF at two gaps (gap1: 900~945nm gap of CMOS and SWIR, gap2: 1375-1380 gap of SWIR
Ref_CMOS_orign=CMOS_rad./Sol_rad_CMOS*(Moon_Sun_Distance^2);
Ref_SWIR_orign=SWIR_rad./Sol_rad_SWIR*(Moon_Sun_Distance^2);
id_1380=find((SWIR_WL-1380)==0);
id_1375=find((SWIR_WL-1375)==0);
gap2_1380=Ref_SWIR_orign(id_1380);
gap2_1375=Ref_SWIR_orign(id_1375);
Ref_SWIR=Ref_SWIR_orign;
if gap2_1380-gap2_1375 > (Ref_SWIR_orign(id_1380+1)-gap2_1380)*2 % detect the presence of gap2 and eliminates it if it is present
    Ref_SWIR(1:id_1375)=Ref_SWIR_orign(1:id_1375)*(gap2_1380/gap2_1375);
else
    disp('---There is no 1375-1380 gap in this spectrum.---');
end
gap1_CMOS=Ref_CMOS_orign(end-9);
gap1_SWIR=Ref_SWIR(1);
Ref_CMOS=Ref_CMOS_orign*(gap1_SWIR/gap1_CMOS); % eliminate gap1

%% plots
sbp=[4,1]; % row and col of the subplots
figure();
subplot(sbp(1),sbp(2),1); % show CMOS image
imagesc(CMOS_cube(:,:,find((CMOS_WL-750)==0))); %750nm image
title(['N',CMOS_file_name(end-8:end-5),'_Rad_',num2str(750),'nm'],'Interpreter','none');
colormap gray
hold on
rectangle('Position',[98-53.8 256-128-53.8 53.8*2 53.8*2],'Curvature',[1 1],'EdgeColor','yellow','LineWidth',0.8);%show the SWIR area
scatter(98,256-128,128,'red','+','LineWidth',1.5);
axis equal
axis tight
axis off
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
legend('Samp_CMOS_rad','Samp_SWIR_rad','Sol_CMOS_rad/10 (scaled for clarity)','Sol_SWIR_rad/10 (scaled for clarity)','Interpreter','none');
subplot(sbp(1),sbp(2),3); % show the calculated REFF
plot(CMOS_WL,Ref_CMOS_orign,'LineWidth',1);
hold on
plot(SWIR_WL,Ref_SWIR_orign,'LineWidth',1);
axis padded
set(gca,'XLim',[400,2450],'XMinorTick','on')
ax=gca;
ax.YLabel.String='Ref.';
legend('CMOS','SWIR','Location','southeast');
subplot(sbp(1),sbp(2),4);  % show the REFF after jointing the gaps
plot(CMOS_WL,Ref_CMOS,'LineWidth',1);
hold on
plot(SWIR_WL,Ref_SWIR,'LineWidth',1);
axis padded
set(gca,'XLim',[400,2450],'XMinorTick','on')
ax=gca;
ax.XLabel.String='Wavelength (nm)';
ax.YLabel.String='Ref.';
legend('CMOS(Scale 900 to SWIR)','SWIR(Scale 1375 to 1380)','Location','southeast','Interpreter','none');
set(gcf,'Position',[500,115,800,700]);


