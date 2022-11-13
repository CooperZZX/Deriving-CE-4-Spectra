%% 本程序用于实现从CE4-SD/SWIR的2BL头文件中提取出所有相关参数
% Author: Zhenxing Zhao
% Date: 2022.4.22
% Input parameter:
%   filename_SD2BL: The filename of SWIR 2BL. If the current filepath is
%   not the 2BL filepath, filename_SD2BL should be the full path.
% Output parameter:
%   Par_all: a table contains all the parameters in the SD2BL file
% Tested under MATLAB 2021a
function [Par_all]=extr_SD2BL_par(filename_SD2BL)
fID = fopen(filename_SD2BL);
sequence_id=[0;0;0];%初始化为0，如果没有在文件中读取到，那么0刚好可以代表异常值。实际只有第1个值有用。
Rover_Location=[0;0;0];%实际只用两个值，经度和维度
Lander_Location=[0;0;0];%实际只用两个值，经度和维度
Rover_LocationXYZ=[0;0;0];%XYZ
Center_Point_LocationXYZ=[0;0;0];%XYZ
Vector_Cartesian_3_Pointing=zeros(3,1);%XYZ
Angle_Pointing_Results=zeros(3,1);%incidence_angle，azimuth_angle，phase_angle
solar_ang=[0;0;0];
Time_start_stop=string(zeros(3,1));
XYZ_names=["X";"Y";"Z"];
Angle_names=["incidence";"azimuth";"phase"];
Lon_Lati=["Long";"Lati";"none"];
while ~feof(fID) % 判断是否为文件末尾
    line_x=fgetl(fID);%读取文件中的行
    if contains(line_x,'<Time_Coordinates>')%<Time_Coordinates>
        while ~contains(line_x,'</Time_Coordinates>')
            line_x=fgetl(fID);%读取文件中的行
            if contains(line_x,'<start_date_time>')
                line_match=char(regexp(line_x,'>[^<]*<','match'));%regexp用正则表达式查找在'>'和'<'之间的内容，将返回的cell类型强制转换为char
                Time_start_stop(1,1)=string(char(line_match(2:end-1)));
            end
            if contains(line_x,'<stop_date_time>')
                line_match=char(regexp(line_x,'>[^<]*<','match'));%regexp用正则表达式查找在'>'和'<'之间的内容，将返回的cell类型强制转换为char
                Time_start_stop(2,1)=string(line_match(2:end-1));
            end             
        end
    end
    if contains(line_x,'<Mission_Area>')%在Mission_Area中查找
        while ~contains(line_x,'</Mission_Area>')
            line_x=fgetl(fID);%读取文件中的行
            if contains(line_x,'<sequence_id>')
                line_match=char(regexp(line_x,'>[^<]*<','match'));%regexp用正则表达式查找在'>'和'<'之间的内容，将返回的cell类型强制转换为char
                sequence_id(1)=str2double(line_match(2:end-1));
            end
            if contains(line_x,'<Rover_Location>')
                while ~contains(line_x,'</Rover_Location>')
                    line_x=fgetl(fID);
                    if contains(line_x,'<longitude')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Rover_Location(1)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'<latitude')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Rover_Location(2)=str2double(line_match(2:end-1));
                    end
                end
            end
            if contains(line_x,'<Lander_Location>')
                while ~contains(line_x,'</Lander_Location>')
                    line_x=fgetl(fID);
                    if contains(line_x,'<longitude')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Lander_Location(1)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'<latitude')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Lander_Location(2)=str2double(line_match(2:end-1));
                    end
                end
            end
            if contains(line_x,'<Rover_LocationXYZ>')
                while ~contains(line_x,'</Rover_LocationXYZ>')
                    line_x=fgetl(fID);
                    if contains(line_x,'</x>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Rover_LocationXYZ(1)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'</y>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Rover_LocationXYZ(2)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'</z>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Rover_LocationXYZ(3)=str2double(line_match(2:end-1));
                    end
                end
            end
            if contains(line_x,'<Center_Point_LocationXYZ>')
                while ~contains(line_x,'</Center_Point_LocationXYZ>')
                    line_x=fgetl(fID);
                    if contains(line_x,'</x>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Center_Point_LocationXYZ(1)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'</y>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Center_Point_LocationXYZ(2)=str2double(line_match(2:end-1));
                    end
                    if contains(line_x,'</z>')
                        line_match=char(regexp(line_x,'>[^<]*<','match'));
                        Center_Point_LocationXYZ(3)=str2double(line_match(2:end-1));
                    end
                end
            end
            %Vector_Cartesian_3_Pointing
            if contains(line_x,'<Vector_Cartesian_3_Pointing>')
                while ~contains(line_x,'</Vector_Cartesian_3_Pointing>')
                    line_x=fgetl(fID);
                    %1
                    if contains(line_x,'<center_point_observe_vector>')
                        while ~contains(line_x,'</center_point_observe_vector>')
                            line_x=fgetl(fID);
                            if contains(line_x,'</x>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Vector_Cartesian_3_Pointing(1,1)=str2double(line_match(2:end-1));
                            end
                            if contains(line_x,'</y>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Vector_Cartesian_3_Pointing(2,1)=str2double(line_match(2:end-1));
                            end
                            if contains(line_x,'</z>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Vector_Cartesian_3_Pointing(3,1)=str2double(line_match(2:end-1));
                            end
                        end
                    end
                end
            end %Vector_Cartesian_3_Pointing
            %Angle_Pointing_Results
            if contains(line_x,'<Angle_Pointing_Results>')
                while ~contains(line_x,'</Angle_Pointing_Results>')
                    line_x=fgetl(fID);
                    %1
                    if contains(line_x,'<center_point>')
                        while ~contains(line_x,'</center_point>')
                            line_x=fgetl(fID);
                            if contains(line_x,'</incidence_angle>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Angle_Pointing_Results(1,1)=str2double(line_match(2:end-1));
                            end
                            if contains(line_x,'</azimuth_angle>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Angle_Pointing_Results(2,1)=str2double(line_match(2:end-1));
                            end
                            if contains(line_x,'</phase_angle>')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                Angle_Pointing_Results(3,1)=str2double(line_match(2:end-1));
                            end
                        end
                    end
                    if contains(line_x,'<solar>')
                        while ~contains(line_x,'</solar>')
                            line_x=fgetl(fID);
                            if contains(line_x,'<incidence_angle')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                solar_ang(1)=str2double(line_match(2:end-1));
                            end
                            if contains(line_x,'<azimuth_angle')
                                line_match=char(regexp(line_x,'>[^<]*<','match'));
                                solar_ang(2)=str2double(line_match(2:end-1));
                            end
                        end
                    end
                end
            end %Angle_Pointing_Results
        end
    end
end
Par_all=[table(sequence_id),table(Time_start_stop),table(Lon_Lati),table(Rover_Location),table(Lander_Location),table(Angle_names),array2table(Angle_Pointing_Results),table(solar_ang),...
         table(XYZ_names),table(Rover_LocationXYZ),table(Center_Point_LocationXYZ),array2table(Vector_Cartesian_3_Pointing)];
%          编号        车坐标         着陆器坐标        车坐标XYZ       Center_Point_LocationXYZ Vector_Cartesian_3_Pointing Angle_Pointing_Results solar_ang
Par_all.Properties.VariableNames={'sequence_id','Time_start_stop','Lon_Lati/deg','Rover_Loc','Lander_Loc','Angle/deg','Angl_C','solar_ang',...
                                      'XYZ/m','Rover_XYZ','Center_XYZ','Vect_C'};
fclose(fID);
end