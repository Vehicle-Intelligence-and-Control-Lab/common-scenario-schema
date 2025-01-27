function [impact_section,pre_crash_true,impact_sample_all,safe_crash_with_AEB,safe_on,safe_off,crash_on,crash_off,driving_time,driving_distance,info,impact_speed] = genCollisionGTVRU(data_path,carmaker_project_path,cur_scenario_selection,param_table)

%%%%%%%%%%%%%%%%%%%%%%%%%% Input
% Data_Path : mat folder directory
% Dir_Save : mat data directory
% Scenario_Path : TestRun file directory
% Cur_Scenario_Selection : Current scenario name
% Tablename : Parameter table name
%%%%%%%%%%%%%%%%%%%%%%%%%% Output
% impact_section
% pre_crash_true
% impact_sample_all
% safe_crash_with_AEB
% Safe_ON
% Safe_OFF
% Crash_ON
% Crash_OFF
% Driving_Time
% Driving_Distance
% info
% Impactspeedresult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
------Collision mode GT generation---
Release Update

ver 050820
새로운 알고리즘
검증 강화
수정리스트 추가
description 추가

ver 050920
알고리즘 완화
GT 검증 강화
description 추가

ver 051020
target 차량의 coordi로 인한 yaw 값 반영

ver 051120
description 추가
불필요한 변수 제거와 같은 코드 정리

ver 051220
description 추가

ver 052020
ego 차량 CG 수정


ver 060220
GT에 AEB Safe,Crash 추가

ver 060320
AEB_on 수정

ver 071320
Lane 추가

ver 121020
Distance, Driving time 추가
%}

%{
GT Data List
- Pre_crash_true      : ground truth for crash or not
- impact_sample_all   : all of impact sample in each scenario
- impact_section      : Collision mode of ego vehicle.
- safe_crash_with_AEB : 0=Safe_ON, 1=Safe_OFF, 2=Crash_ON, 3=Crash_OFF
- safe_ON             : Count of Safe,  AEB on
- safe_OFF            : Count of Safe,  AEB off
- crash_ON            : Count of Crash, AEB on
- crash_OFF           : Count of Crash, AEB off
- driving_time
- driving_distance
Variables of each Scenario
- Scenario name
- Data_Folder_Dir
- Switch_Export_ERG2MAT      1 : Export,   0 : Do not export
- Switch_Plot_ImpactScene    1 : Plot,     0 : Do not plot
* Running GT generator via .mlx, recommend to turn on Switch_Plot_ImpactScene.
%}

%----------------------------------------
Switch_FOV = 0;
Switch_Plot_ImpactScene = 0;
%% ACL GT generator
% clearvars -except Data_Path Dir_Save Scenario_Path Cur_Scenario_Selection Tablename
Scenario_Path = [carmaker_project_path '\Data'];

% GT Create date
date_time = datestr(now);
date_time_index = strfind(date_time,' ');

% Parameter space load
Parameter_Space =  param_table;

num=height(Parameter_Space(:,1));


Scenario_File = fileread([Scenario_Path '\TestRun\' cur_scenario_selection]);

Search_Road = char(regexp(Scenario_File,'[^\n]*.rd5[^\n]*','match'));
info.road = Search_Road(strfind(Search_Road,'=')+2:end-1);
info.date = date_time(1:date_time_index-1);
info.time = date_time(date_time_index+1:end);

Search_Vehicle = char(regexp(Scenario_File,'[^\n]*Vehicle =[^\n]*','match'));
info.vehicle = Search_Vehicle(strfind(Search_Vehicle,'=')+2:end-1);

info.exportScript = mfilename;

Vehicle_File = fileread([Scenario_Path '\Vehicle\' info.vehicle]);
Road_File = fileread([Scenario_Path '\Road\' info.road]);

%% Parameters of Vehicles

Search_Width = char(regexp(Vehicle_File,'[^\n]*CarGen.Vehicle.Width =[^\n]*','match'));
EGO_WIDTH = str2double(Search_Width(strfind(Search_Width,'=')+2:end-1))*1/1000;

Search_Length = char(regexp(Vehicle_File,'[^\n]*CarGen.Vehicle.Length =[^\n]*','match'));
EGO_LENGTH = str2double(Search_Length(strfind(Search_Length,'=')+2:end-1))*1/1000;

Search_Ego_CG2Rear_Bumper = strtrim(char(regexp(Vehicle_File,'[^\n]*Body.pos =[^\n]*','match')));
eval(['tmp_Ego_CG2Rear_Bumper = [' Search_Ego_CG2Rear_Bumper(strfind(Search_Ego_CG2Rear_Bumper,'=')+2:end) '];']);
EGO_CG2_REAR_BUMPER = tmp_Ego_CG2Rear_Bumper(1,1);
EGO_CG2_FRONT_BUMPER = EGO_LENGTH - EGO_CG2_REAR_BUMPER;

%% Parameters of Traffic and Sensor

Search_Traffic_Num = strtrim(char(regexp(Scenario_File,'[^\n]*Traffic.N =[^\n]*','match')));
Traffic_Num = str2double(Search_Traffic_Num(strfind(Search_Traffic_Num,'=')+2:end));

Search_Sensor_Num = strtrim(char(regexp(Vehicle_File,'[^\n]*Sensor.Object.N =[^\n]*','match')));
Sensor_Num = str2double(Search_Sensor_Num(strfind(Search_Sensor_Num,'=')+2:end));

if Sensor_Num == 0
    disp('Carmaker 시나리오 파일에서 Object 센서가 없습니다.');
else
    Sensor_Name_Cell = cell(1,Sensor_Num);
    
    for i = 1:Sensor_Num
        Search_Sensor_name_char = strtrim(char(regexp(Vehicle_File,['[^\n]*Sensor.Object.' num2str(i-1) '.name =[^\n]*'],'match')));
        tmp_Sensor_name_char = Search_Sensor_name_char(strfind(Search_Sensor_name_char,'=')+2:end);
        
        Sensor_Name_Cell(1,i) = cellstr(tmp_Sensor_name_char);
        
    end
    
    Traffic_Name_Cell = cell(1,Traffic_Num);
    
    for i = 1:Traffic_Num
        
        Search_Traffic_name_char = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(i-1) '.Name =[^\n]*'],'match')));
        tmp_Traffic_name_char = Search_Traffic_name_char(strfind(Search_Traffic_name_char,'=')+2:end);
        
        Traffic_Name_Cell(1,i) = cellstr(tmp_Traffic_name_char);
        
    end
end

if length(Traffic_Name_Cell(1,:)) == 1
    tmp_Traffic_Name = char(Traffic_Name_Cell(1,1));
    
    Search_Traffic_Dimension = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.0.Basics.Dimension =[^\n]*'],'match')));
    eval(['tmp_Traffic_Dimension = [' Search_Traffic_Dimension(strfind(Search_Traffic_Dimension,'=')+2:end) '];']);
    
    Search_Traffic_CG2Rear_Bumper = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.0.Basics.Fr12CoM =[^\n]*'],'match')));
    eval(['TARGET_CG2_REAR_BUMPER = ' Search_Traffic_CG2Rear_Bumper(strfind(Search_Traffic_CG2Rear_Bumper,'=')+2:end) ';']);
    
    tmp_Traffic_Length = tmp_Traffic_Dimension(1,1);
    TARGET_WIDTH = tmp_Traffic_Dimension(1,2);
    TARGET_CG2_FRONT_BUMPER = tmp_Traffic_Length - TARGET_CG2_REAR_BUMPER;
    TARGET_TRAFFIC_Name = tmp_Traffic_Name;
else
    for SIG_Num = 1:length(Traffic_Name_Cell(1,:))
        tmp_Traffic_Name = char(Traffic_Name_Cell(1,SIG_Num));
        
        if strcmp(tmp_Traffic_Name,'RV')
            Search_Traffic_Dimension = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(SIG_Num-1) '.Basics.Dimension =[^\n]*'],'match')));
            eval(['tmp_Traffic_Dimension = [' Search_Traffic_Dimension(strfind(Search_Traffic_Dimension,'=')+2:end) '];']);
            
            Search_Traffic_CG2Rear_Bumper = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(SIG_Num-1) '.Basics.Fr12CoM =[^\n]*'],'match')));
            eval(['TARGET_CG2_REAR_BUMPER = ' Search_Traffic_CG2Rear_Bumper(strfind(Search_Traffic_CG2Rear_Bumper,'=')+2:end) ';']);
            
            tmp_Traffic_Length = tmp_Traffic_Dimension(1,1);
            TARGET_WIDTH = tmp_Traffic_Dimension(1,2);
            TARGET_CG2_FRONT_BUMPER = tmp_Traffic_Length - TARGET_CG2_REAR_BUMPER;
            TARGET_TRAFFIC_Name = tmp_Traffic_Name;
        end
    end
end


%% GT generator

disp('   ACL GT generator ver 112321')
disp('  ')
disp(['   GT generator started  at : ', char(datetime('now'))])
disp('  ')

disp(['    Scenario : ', cur_scenario_selection])
disp(['    Data counts of the scenario : ', num2str(num)])
disp('  ')
disp('  ')

PATH_Scenario_Folder = [data_path '\' cur_scenario_selection];

cd(PATH_Scenario_Folder);
Param_table = param_table;

Variable_array = Param_table.Variables;
Variable_name = Param_table.Properties.VariableNames;

eval(['Variable_array = Param_table.Variables;'])
eval(['Variable_name = Param_table.Properties.VariableNames;'])
eval(['num = height(Param_table);'])

%% Create Label

impact_speed=zeros(num,1);
AEB_on=zeros(num,1);
ImpactHeadingresult=zeros(num,1);
safe_crash_with_AEB=zeros(num,1);
headingA=zeros(num,1);

pre_crash_true=zeros(num,1);

impact_sample_all=zeros(num,1);
impact_section_sample_all = zeros(num,1);

impact_section=zeros(num,3); % Collision mode
impact_prediction=zeros(num,1);

leftpoint=zeros(100,8);
rightpoint=zeros(100,8);
driving_distance=0;
driving_time=0;
%% Load scenario data and Calculate points of polygon at impact sample


for j = 1 : num
    Data_index = j;
    matFile_Name = [cur_scenario_selection '_data_' num2str(Variable_array(j,1)+1) '.mat'];
    load(matFile_Name)

    
    %% Parameter
    
    IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE                     = 1;  %      [rad]              Global heading angle
    IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X                             = 2;  %      [m]                Global longitudinal position
    IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y                             = 3;  %      [m]                Global lateral position
    IN_VEHICLE_SENSOR.MEASURE.VEHICLE_SPEED                         = 4;  %      [m/s]              absolute velocity
    IN_VEHICLE_SENSOR.MEASURE.LONG_ACC                              = 5;  %      [m/s^2]
    IN_VEHICLE_SENSOR.MEASURE.LONG_VEL                              = 6;  %     [m/s]
    IN_VEHICLE_SENSOR.MEASURE.LAT_VEL                               = 7;  %     [m/s]
    
    IN_VEHICLE_SENSOR.STATE_NUMBER                                  = length(fieldnames(IN_VEHICLE_SENSOR.MEASURE));
    
    clearvars CLASS_B
    % CLASS B
    CLASS_B.MEASURE.GLO_HEADING_ANGLE                           = 1;  %      [rad]                                            global 좌표계에서의 heading angle
    CLASS_B.MEASURE.GLO_POS_Y                                   = 2;  %      [m]                                             position = 뒷범퍼 중심
    CLASS_B.MEASURE.GLO_POS_X                                   = 3;  %      [m]
    CLASS_B.MEASURE.GLO_VEL_Y                                   = 4;  %      [m/s]
    CLASS_B.MEASURE.GLO_VEL_X                                   = 5;  %      [m/s]
    CLASS_B.MEASURE.WIDTH                                       = 6;  %      [m]
    CLASS_B.MEASURE.LENGTH                                      = 7;  %      [m]
    CLASS_B.MEASURE.CLASSIFICATION                              = 8;
    
    CLASS_B.PREPROCESSING.REL_POS_Y                             = 8;  %     [m]
    CLASS_B.PREPROCESSING.REL_POS_X                             = 9;  %     [m]
    CLASS_B.PREPROCESSING.REL_VEL_Y                             = 10;  %     [m/s]
    CLASS_B.PREPROCESSING.REL_VEL_X                             = 11;  %     [m/s]
    CLASS_B.PREPROCESSING.HEADING_ANGLE                         = 12;  %     [rad]
    
    CLASS_B.MEASURE.STATE_NUMBER                                = length(fieldnames(CLASS_B.MEASURE)); %                      Class_B 에서 출력되는 최대 state 개수
    CLASS_B.PREPROCESSING.STATE_NUMBER                          = length(fieldnames(CLASS_B.PREPROCESSING)); %                       Preprocessing 에서 추가될 state 개수
    CLASS_B.STATE_NUMBER                                        = CLASS_B.MEASURE.STATE_NUMBER + CLASS_B.PREPROCESSING.STATE_NUMBER;
    CLASS_B.TRACK_NUMBER                                        = 8;
    
    % Description
    CLASS_B.DESCRIPTION_CLASSIFICATION.UNDECIDED               = 0;
    CLASS_B.DESCRIPTION_CLASSIFICATION.CAR                     = 1;
    CLASS_B.DESCRIPTION_CLASSIFICATION.PEDESTRIAN              = 2;
    CLASS_B.DESCRIPTION_CLASSIFICATION.BICYCLE                 = 3;
    CLASS_B.DESCRIPTION_CLASSIFICATION.MOTOR_BIKE              = 4;
    
    
    %% Initialization
    sim_time = data.Time.data;
    
    In_Vehicle_Sensor = zeros(IN_VEHICLE_SENSOR.STATE_NUMBER, 1, length(sim_time));
    Class_B = zeros(CLASS_B.MEASURE.STATE_NUMBER, CLASS_B.TRACK_NUMBER, length(sim_time));
    
    %% Parameters of Ego Vehicle
    Search_Width = char(regexp(Vehicle_File,'[^\n]*CarGen.Vehicle.Width =[^\n]*','match'));
    EGO_WIDTH = str2double(Search_Width(strfind(Search_Width,'=')+2:end-1))*1/1000;
    
    Search_Length = char(regexp(Vehicle_File,'[^\n]*CarGen.Vehicle.Length =[^\n]*','match'));
    EGO_LENGTH = str2double(Search_Length(strfind(Search_Length,'=')+2:end-1))*1/1000;
    
    Search_Ego_CG2Rear_Bumper = strtrim(char(regexp(Vehicle_File,'[^\n]*Body.pos =[^\n]*','match')));
    eval(['tmp_Ego_CG2Rear_Bumper = [' Search_Ego_CG2Rear_Bumper(strfind(Search_Ego_CG2Rear_Bumper,'=')+2:end) '];']);
    EGO_CG2_REAR_BUMPER = tmp_Ego_CG2Rear_Bumper(1,1);
    EGO_CG2_FRONT_BUMPER = EGO_LENGTH - EGO_CG2_REAR_BUMPER;
    
    EGO_VEHICLE.EGO_WIDTH = EGO_WIDTH;
    EGO_VEHICLE.EGO_LENGTH = EGO_LENGTH;
    
    %% Parameters of Traffic and Sensor
    
    Search_Traffic_Num = strtrim(char(regexp(Scenario_File,'[^\n]*Traffic.N =[^\n]*','match')));
    Traffic_Num = str2double(Search_Traffic_Num(strfind(Search_Traffic_Num,'=')+2:end));
    
    Search_Sensor_Num = strtrim(char(regexp(Vehicle_File,'[^\n]*Sensor.Object.N =[^\n]*','match')));
    Sensor_Num = str2double(Search_Sensor_Num(strfind(Search_Sensor_Num,'=')+2:end));
    
    if Sensor_Num == 0
        disp('Carmaker 시나리오 파일에서 Object 센서가 없습니다.');
    else
        Sensor_Name_Cell = cell(1,Sensor_Num);
        
        for i = 1:Sensor_Num
            Search_Sensor_name_char = strtrim(char(regexp(Vehicle_File,['[^\n]*Sensor.Object.' num2str(i-1) '.name =[^\n]*'],'match')));
            tmp_Sensor_name_char = Search_Sensor_name_char(strfind(Search_Sensor_name_char,'=')+2:end);
            
            Sensor_Name_Cell(1,i) = cellstr(tmp_Sensor_name_char);
            
        end
        
        Traffic_Name_Cell = cell(1,Traffic_Num);
        
        for i = 1:Traffic_Num
            
            Search_Traffic_name_char = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(i-1) '.Name =[^\n]*'],'match')));
            tmp_Traffic_name_char = Search_Traffic_name_char(strfind(Search_Traffic_name_char,'=')+2:end);
            
            Traffic_Name_Cell(1,i) = cellstr(tmp_Traffic_name_char);
            
        end
    end
    
    
    
    if length(Traffic_Name_Cell(1,:)) == 1
        tmp_Traffic_Name = char(Traffic_Name_Cell(1,1));
        
        Search_Traffic_Dimension = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.0.Basics.Dimension =[^\n]*'],'match')));
        eval(['tmp_Traffic_Dimension = [' Search_Traffic_Dimension(strfind(Search_Traffic_Dimension,'=')+2:end) '];']);
        
        Search_Traffic_CG2Rear_Bumper = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.0.Basics.Fr12CoM =[^\n]*'],'match')));
        eval(['TARGET_CG2_REAR_BUMPER = ' Search_Traffic_CG2Rear_Bumper(strfind(Search_Traffic_CG2Rear_Bumper,'=')+2:end) ';']);
        
        tmp_Traffic_Length = tmp_Traffic_Dimension(1,1);
        TARGET_WIDTH = tmp_Traffic_Dimension(1,2);
        TARGET_CG2_FRONT_BUMPER = tmp_Traffic_Length - TARGET_CG2_REAR_BUMPER;
        TARGET_TRAFFIC_Name = tmp_Traffic_Name;
        TARGET_LENGTH = TARGET_CG2_FRONT_BUMPER + TARGET_CG2_REAR_BUMPER;
        
        Class_B(CLASS_B.MEASURE.WIDTH,1, :) = TARGET_WIDTH;
        Class_B(CLASS_B.MEASURE.LENGTH,1, :) = TARGET_LENGTH;
        
        % 추후 환경 파일 이용해서 shape 정보 추가하기
        Class_B(CLASS_B.MEASURE.CLASSIFICATION,1, :) = CLASS_B.DESCRIPTION_CLASSIFICATION.CAR;
        
    else
        for SIG_Num = 1:length(Traffic_Name_Cell(1,:))
            tmp_Traffic_Name = char(Traffic_Name_Cell(1,SIG_Num));
            
            Search_Traffic_Dimension = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(SIG_Num-1) '.Basics.Dimension =[^\n]*'],'match')));
            eval(['tmp_Traffic_Dimension = [' Search_Traffic_Dimension(strfind(Search_Traffic_Dimension,'=')+2:end) '];']);
            
            Search_Traffic_CG2Rear_Bumper = strtrim(char(regexp(Scenario_File,['[^\n]*Traffic.' num2str(SIG_Num-1) '.Basics.Fr12CoM =[^\n]*'],'match')));
            eval(['TARGET_CG2_REAR_BUMPER = ' Search_Traffic_CG2Rear_Bumper(strfind(Search_Traffic_CG2Rear_Bumper,'=')+2:end) ';']);
            
            tmp_Traffic_Length = tmp_Traffic_Dimension(1,1);
            TARGET_WIDTH = tmp_Traffic_Dimension(1,2);
            TARGET_CG2_FRONT_BUMPER = tmp_Traffic_Length - TARGET_CG2_REAR_BUMPER;
            TARGET_TRAFFIC_Name = tmp_Traffic_Name;
            TARGET_LENGTH = TARGET_CG2_FRONT_BUMPER + TARGET_CG2_REAR_BUMPER;
            
            eval(['Class_B(CLASS_B.MEASURE.WIDTH,' num2str(SIG_Num) ', :) = TARGET_WIDTH;']);
            eval(['Class_B(CLASS_B.MEASURE.LENGTH,' num2str(SIG_Num) ', :) = TARGET_LENGTH;']);
            
            if strcmp(tmp_Traffic_Name, 'P00')
                eval(['Class_B(CLASS_B.MEASURE.CLASSIFICATION,' num2str(SIG_Num) ', :) = CLASS_B.DESCRIPTION_CLASSIFICATION.PEDESTRIAN;']);
            elseif strcmp(tmp_Traffic_Name, 'C00')
                eval(['Class_B(CLASS_B.MEASURE.CLASSIFICATION,' num2str(SIG_Num) ', :) = CLASS_B.DESCRIPTION_CLASSIFICATION.BICYCLE;']);
            else
                eval(['Class_B(CLASS_B.MEASURE.CLASSIFICATION,' num2str(SIG_Num) ', :) = CLASS_B.DESCRIPTION_CLASSIFICATION.CAR;']);
            end
            
        end
    end
    
    
    
    %% Preprocessing - Coordinate Transform
    
    Traffic_Number = Traffic_Num;
    
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE,:) = data.Car_Yaw.data';
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y,:) = data.Car_ty.data';  % Fr0(global)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X,:) = data.Car_tx.data';  % Fr0(global)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.VEHICLE_SPEED,:) = data.Car_v.data'; % wheel velocity
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LONG_ACC,:) = data.Car_ax.data'; % Fr1(body fixed)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LONG_VEL,:) = data.Car_vx.data'; % Fr1(body fixed)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LAT_VEL,:) = data.Car_vy.data'; % Fr1(body fixed)
    
    for SIG_Num = 1:Traffic_Number
        VAR_Num = SIG_Num;
        
        tmp_Traffic_Name = char(Traffic_Name_Cell(1,SIG_Num));
        
        eval(['Class_B(CLASS_B.MEASURE.GLO_POS_Y,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_ty.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_POS_X,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_tx.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_VEL_Y,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_v_0_y.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_VEL_X,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_v_0_x.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_HEADING_ANGLE,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_rz.data;']);
    end
    
    
    for track_number = 1:Traffic_Number
        
        Class_B(CLASS_B.PREPROCESSING.HEADING_ANGLE, track_number, :) = (Class_B(CLASS_B.MEASURE.GLO_HEADING_ANGLE, track_number, :) -In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :));
        
        X_FrontCenter_A = EGO_CG2_FRONT_BUMPER.*cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X, 1, :);
        Y_FrontCenter_A = EGO_CG2_FRONT_BUMPER.*sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y, 1, :);
        
        X_AB = Class_B(CLASS_B.MEASURE.GLO_POS_X, track_number, :) - X_FrontCenter_A;
        Y_AB = Class_B(CLASS_B.MEASURE.GLO_POS_Y, track_number, :) - Y_FrontCenter_A;
        
        x_AB = X_AB .* cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Y_AB .* sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :));
        y_AB = -X_AB .* sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Y_AB .* cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :));
        
        Class_B(CLASS_B.PREPROCESSING.REL_POS_Y, track_number, :) = y_AB;
        Class_B(CLASS_B.PREPROCESSING.REL_POS_X, track_number, :) = x_AB;
        
        Class_B(CLASS_B.PREPROCESSING.REL_VEL_X, track_number, :) = Class_B(CLASS_B.MEASURE.GLO_VEL_X, track_number, :) .* cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Class_B(CLASS_B.MEASURE.GLO_VEL_Y, track_number, :).*sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) - In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LONG_VEL, 1, :);
        Class_B(CLASS_B.PREPROCESSING.REL_VEL_Y, track_number, :) = -Class_B(CLASS_B.MEASURE.GLO_VEL_X, track_number, :) .* sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Class_B(CLASS_B.MEASURE.GLO_VEL_Y, track_number, :).*cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) - In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LAT_VEL, 1, :);
        
    end
    
    if Switch_FOV
        
        for i_sensor = 1:Sensor_Num
            eval(['sensor' num2str(i_sensor) 'Detected = data.Sensor_Object_' char(Sensor_Name_Cell(1,i_sensor)) '_relvTgt_dtct;'])
        end
        
        for time_index = 1:length(sim_time)
            
            tmpDetectedFlag = 0;
            for i_sensor = 1:Sensor_Num
                eval(['tmpDetectedFlag = tmpDetectedFlag + sensor' num2str(i_sensor) 'Detected(' num2str(time_index) ');'])
            end
            
            if tmpDetectedFlag == 0
                Class_B(:, :, time_index) = zeros(CLASS_B.STATE_NUMBER,1);
            end
        end
    end
        
    
    %%
    Car_Yaw = data.Car_Yaw.data;
    Car_tx = data.Car_tx.data;
    Car_ty = data.Car_ty.data;
    Car_v = data.Car_v.data;
    Car_a = data.Car_ax.data;
    Car_vy = data.Car_vy.data;
    
    sim_time = data.Time.data;
    
    eval(['T00_v = data.Traffic_' TARGET_TRAFFIC_Name '_LongVel.data;']);
    eval(['T00_vy = data.Traffic_' TARGET_TRAFFIC_Name '_LatVel.data;']);
    eval(['T00_yaw = data.Traffic_' TARGET_TRAFFIC_Name '_rz.data;']);
    eval(['T00_x = data.Traffic_' TARGET_TRAFFIC_Name '_tx.data;']);
    eval(['T00_y = data.Traffic_' TARGET_TRAFFIC_Name '_ty.data;']);
    eval(['rv_acc = data.Traffic_' TARGET_TRAFFIC_Name '_LongAcc.data;']);
    
    
    
    if Switch_FOV
        for sim_index = 1:length(sim_time)
            if Sensor_1_detected(1,sim_index) == 0 && Sensor_2_detected(1,sim_index) == 0
                T00_v(1,sim_index) = 0;
                T00_vy(1,sim_index) = 0;
                T00_yaw(1,sim_index) = 0;
                T00_x(1,sim_index) = 0;
                T00_y(1,sim_index) = 0;
                rv_acc(1,sim_index) = 0;
            end
        end
    end
    
    
    %         AEB_active=0;
    AEB_active=data.LongCtrl_AEB_IsActive.data;
    
    
    Relative_POS_X = -Car_tx+T00_x;
    Relative_POS_Y = -Car_ty+T00_y;
    
    Relative_Vel = -Car_v+T00_v;
    
    Heading_Angle = -Car_Yaw + pi/2;
    
    
    vx_rel=Relative_Vel.*cos(Heading_Angle);
    vy_rel=Relative_Vel.*sin(Heading_Angle);
    
    
    Impact_v_rel=zeros(length(sim_time),1);
    ImpactHVSpeed=zeros(length(sim_time),1);
    ImpactHeading=zeros(length(sim_time),1);
    for i=1:length(sim_time)
        if data.Sensor_Collision_Vhcl_Fr1_Count.data(i)>0
            Impact_v_rel(i)=Car_v(i)*3.6;
            ImpactHVSpeed(i)=Car_v(i)*3.6;
            ImpactHeading(i)=T00_yaw(i)*180/pi;
        end
    end
    Impact_v_rel=Impact_v_rel';
    ImpactHVSpeed=ImpactHVSpeed';
    ImpactHeading=ImpactHeading';
    
    
    Impactspeedresult(j)=max(ImpactHVSpeed);
    ImpactHeadingresult(j)=max(ImpactHeading);
    [~,impact_sample,imv]=find(ImpactHVSpeed,1);
    if Impactspeedresult(j)~=0
        headingA(j)=(Car_Yaw(impact_sample-1)-(pi/2))...
            -(T00_yaw(impact_sample-1)-(pi/2));
    end
    
    
    if Impactspeedresult(j)~=0
        pre_crash_true(j)=1;
    else
        pre_crash_true(j)=0;
    end
    
    AEB_on(j)=max(AEB_active);
    
    if pre_crash_true(j)~=0 && AEB_on(j)~=0        %AEB on,  Crash
        safe_crash_with_AEB(j)=2;
    elseif pre_crash_true(j)~=0 && AEB_on(j)==0    %AEB OFF, Crash
        safe_crash_with_AEB(j)=3;
    elseif pre_crash_true(j)==0 && AEB_on(j)~=0    %AEB on,  Safe
        safe_crash_with_AEB(j)=0;
    else                                           %AEB OFF, Safe
        safe_crash_with_AEB(j)=1;
    end
    
    
    if ~isempty(impact_sample)
        impact_sample_all(j)=impact_sample;
    end
    
    if isempty(impact_sample)
        continue
    end
    
    endtime=impact_sample+50;
    
    
    if  length(endtime)<length(sim_time)
        endtime=max(length(sim_time));
    end
    
    for time_index = impact_sample-30:impact_sample+30
        
        if time_index == impact_sample
            a = 1;
        end
        
        egoPoint(time_index,:)= plotSimpleEgoCarGlobal(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, time_index),...
            In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y, time_index), In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X, time_index), [1 1 1 1 1], 1, '-',...
            EGO_CG2_FRONT_BUMPER,EGO_CG2_REAR_BUMPER,EGO_WIDTH/2);
        
        for i_traffic = 1:Traffic_Num
            targetPoint(time_index,:) = plotSimpleTargetCarGlobal(Class_B(CLASS_B.MEASURE.GLO_HEADING_ANGLE, i_traffic, time_index),...
                Class_B(CLASS_B.MEASURE.GLO_POS_Y, i_traffic, time_index), Class_B(CLASS_B.MEASURE.GLO_POS_X, i_traffic, time_index) ,[1 1 1 1 1], 1, '-',...
                TARGET_CG2_FRONT_BUMPER,TARGET_CG2_REAR_BUMPER,TARGET_WIDTH/2);
            
            yq1 = targetPoint(time_index,1:4); % target points - Global Y
            xq1 = targetPoint(time_index,5:8); % target points - Global X
            
            yq2 = egoPoint(time_index,1:4); % ego points - Global Y
            xq2 = egoPoint(time_index,5:8); % ego points - Global X
            
            yv1=[yq1 yq1(1)]; % target polygon
            xv1=[xq1 xq1(1)];
            
            yv2=[yq2 yq2(1)]; % ego polygon
            xv2=[xq2 xq2(1)];
            
            [in1, on1]=inpolygon(xq2,yq2,xv1,yv1) ; % ego pt in target polygon
            [in2, on2]=inpolygon(xq1,yq1,xv2,yv2) ; % target pt in ego polygon
            
            if max(in1)+max(in2) ~= 0
                break
            elseif time_index == impact_sample && max(in1)+max(in2) == 0
                P=[xq1' yq1'];
                PQ = [xq2' yq2'];
            end
        end
        
        if max(in1)+max(in2) ~= 0
            break
        end
        
        % 확인용
        %             CMpt11 = [xq2(4), yq2(4)];
        %             CMpt14 = [xq2(1), yq2(1)];
        %             CMpt61 = [xq2(3), yq2(3)];
        %             CMpt64 = [xq2(2), yq2(2)];
        %
        %             CMpt12 = 2/3*CMpt11 + 1/3*CMpt14;
        %             CMpt13 = 1/3*CMpt11 + 2/3*CMpt14;
        %
        %             CMpt62 = 2/3*CMpt61 + 1/3*CMpt64;
        %             CMpt63 = 1/3*CMpt61 + 2/3*CMpt64;
        %
        %             CMpt21 = 4/5*CMpt11 + 1/5*CMpt61;
        %             CMpt31 = 3/5*CMpt11 + 2/5*CMpt61;
        %             CMpt41 = 2/5*CMpt11 + 3/5*CMpt61;
        %             CMpt51 = 1/5*CMpt11 + 4/5*CMpt61;
        %
        %             CMpt24 = 4/5*CMpt14 + 1/5*CMpt64;
        %             CMpt34 = 3/5*CMpt14 + 2/5*CMpt64;
        %             CMpt44 = 2/5*CMpt14 + 3/5*CMpt64;
        %             CMpt54 = 1/5*CMpt14 + 4/5*CMpt64;
        %
        %
        %             figure()
        %             plot(xv1,yv1);
        %             hold on
        %             plot(xv2,yv2);
        %
        %             line([CMpt12(1),CMpt62(1)],[CMpt12(2),CMpt62(2)],'Color','k')
        %             line([CMpt13(1),CMpt63(1)],[CMpt13(2),CMpt63(2)],'Color','k')
        %             line([CMpt21(1),CMpt24(1)],[CMpt21(2),CMpt24(2)],'Color','k')
        %             line([CMpt31(1),CMpt34(1)],[CMpt31(2),CMpt34(2)],'Color','k')
        %             line([CMpt41(1),CMpt44(1)],[CMpt41(2),CMpt44(2)],'Color','k')
        %             line([CMpt51(1),CMpt54(1)],[CMpt51(2),CMpt54(2)],'Color','k')
        %
        %             plot(xq1(in2),yq1(in2),'o');
        %             plot(xq2(in1),yq2(in1),'o');
        %             xlabel('Y (m)')
        %             ylabel('X (m)')
        
    end
    
    
    if sum(in1) + sum(in2) ~= 0
        inpolygon_sample_all(time_index) = 1;
    end
    
    CMpt11 = [xq2(4), yq2(4)];
    CMpt15 = [xq2(1), yq2(1)];
    CMpt61 = [xq2(3), yq2(3)];
    CMpt65 = [xq2(2), yq2(2)];
    
    CMpt12 = 3/4*CMpt11 + 1/4*CMpt15;
    CMpt13 = 1/2*CMpt11 + 1/2*CMpt15;
    CMpt14 = 1/4*CMpt11 + 3/4*CMpt15;
    
    CMpt62 = 3/4*CMpt61 + 1/4*CMpt65;
    CMpt63 = 2/4*CMpt61 + 2/4*CMpt65;
    CMpt64 = 1/4*CMpt61 + 3/4*CMpt65;
    
    CMpt21 = 4/5*CMpt11 + 1/5*CMpt61;
    CMpt31 = 3/5*CMpt11 + 2/5*CMpt61;
    CMpt41 = 2/5*CMpt11 + 3/5*CMpt61;
    CMpt51 = 1/5*CMpt11 + 4/5*CMpt61;
    
    CMpt25 = 4/5*CMpt15 + 1/5*CMpt65;
    CMpt35 = 3/5*CMpt15 + 2/5*CMpt65;
    CMpt45 = 2/5*CMpt15 + 3/5*CMpt65;
    CMpt55 = 1/5*CMpt15 + 4/5*CMpt65;
    
    if sum(in1) == 1
        collision_pt_ego = [xq2(in1),yq2(in1)];
    elseif sum(in1) == 2
        collision_pt_ego = [xq2(in1),yq2(in1)];
    elseif sum(in1) == 0
        collision_pt_ego = [-892,-892];
    end
    
    if sum(in2) == 1
        collision_pt_target = [xq1(in2),yq1(in2)];
    elseif sum(in2) == 2
        collision_pt_target = [xq1(in2),yq1(in2)];
    elseif sum(in2) == 0
        collision_pt_target = [-892,-892];
    end
    
    polygon_x1.x = [CMpt11(1) CMpt61(1) CMpt62(1) CMpt12(1) CMpt11(1)];
    polygon_x1.y = [CMpt11(2) CMpt61(2) CMpt62(2) CMpt12(2) CMpt11(2)];
    
    polygon_x2.x = [CMpt12(1) CMpt62(1) CMpt63(1) CMpt13(1) CMpt12(1)];
    polygon_x2.y = [CMpt12(2) CMpt62(2) CMpt63(2) CMpt13(2) CMpt12(2)];
    
    polygon_x3.x = [CMpt13(1) CMpt63(1) CMpt64(1) CMpt14(1) CMpt13(1)];
    polygon_x3.y = [CMpt13(2) CMpt63(2) CMpt64(2) CMpt14(2) CMpt13(2)];
    
    polygon_x4.x = [CMpt14(1) CMpt64(1) CMpt65(1) CMpt15(1) CMpt14(1)];
    polygon_x4.y = [CMpt14(2) CMpt64(2) CMpt65(2) CMpt15(2) CMpt14(2)];
    
    polygon_1y.x = [CMpt11(1) CMpt21(1) CMpt25(1) CMpt15(1) CMpt11(1)];
    polygon_1y.y = [CMpt11(2) CMpt21(2) CMpt25(2) CMpt15(2) CMpt11(2)];
    
    polygon_2y.x = [CMpt21(1) CMpt31(1) CMpt35(1) CMpt25(1) CMpt21(1)];
    polygon_2y.y = [CMpt21(2) CMpt31(2) CMpt35(2) CMpt25(2) CMpt21(2)];
    
    polygon_3y.x = [CMpt31(1) CMpt41(1) CMpt45(1) CMpt35(1) CMpt31(1)];
    polygon_3y.y = [CMpt31(2) CMpt41(2) CMpt45(2) CMpt35(2) CMpt31(2)];
    
    polygon_4y.x = [CMpt41(1) CMpt51(1) CMpt55(1) CMpt45(1) CMpt41(1)];
    polygon_4y.y = [CMpt41(2) CMpt51(2) CMpt55(2) CMpt45(2) CMpt41(2)];
    
    polygon_5y.x = [CMpt51(1) CMpt61(1) CMpt65(1) CMpt55(1) CMpt51(1)];
    polygon_5y.y = [CMpt51(2) CMpt61(2) CMpt65(2) CMpt55(2) CMpt51(2)];
    
    
    if Switch_Plot_ImpactScene == 1
        
        figure()
        plot(xv1,yv1) % target polygon
        hold on
        plot(xv2, yv2) % ego polygon
        
        line([CMpt12(1),CMpt62(1)],[CMpt12(2),CMpt62(2)],'Color','k')
        line([CMpt13(1),CMpt63(1)],[CMpt13(2),CMpt63(2)],'Color','k')
        line([CMpt14(1),CMpt64(1)],[CMpt14(2),CMpt64(2)],'Color','k')
        
        line([CMpt21(1),CMpt25(1)],[CMpt21(2),CMpt25(2)],'Color','k')
        line([CMpt31(1),CMpt35(1)],[CMpt31(2),CMpt35(2)],'Color','k')
        line([CMpt41(1),CMpt45(1)],[CMpt41(2),CMpt45(2)],'Color','k')
        line([CMpt51(1),CMpt55(1)],[CMpt51(2),CMpt55(2)],'Color','k')
        
        %             line([polygon_x1.x], [polygon_x1.y], 'color', 'r')
        %             line([polygon_x2.x], [polygon_x2.y], 'color', 'g')
        %             line([polygon_x3.x], [polygon_x3.y], 'color', 'b')
        %             line([polygon_x4.x], [polygon_x4.y], 'color', 'c')
        
        %             line([polygon_1y.x], [polygon_1y.y], 'color', 'r')
        %             line([polygon_2y.x], [polygon_2y.y], 'color', 'g')
        %             line([polygon_3y.x], [polygon_3y.y], 'color', 'b')
        %             line([polygon_4y.x], [polygon_4y.y], 'color', 'c')
        %             line([polygon_5y.x], [polygon_5y.y], 'color', 'm')
        
        
        if sum(in1) == 1 && sum(in2) == 0
            plot(collision_pt_ego(1),collision_pt_ego(2) ,'r*')
            
        elseif sum(in1) == 2 && sum(in2) == 0
            plot([collision_pt_ego(1),collision_pt_ego(2)],...
                [collision_pt_ego(3),collision_pt_ego(4)] ,'r*')
        end
        
        if sum(in2) == 1 && sum(in1) == 0
            plot(collision_pt_target(1),collision_pt_target(2) ,'r*')
        elseif sum(in2) == 2 && sum(in1) == 0
            plot([collision_pt_target(1),collision_pt_target(2)],...
                [collision_pt_target(3),collision_pt_target(4)] ,'r*')
        end
        if sum(in2) == 1 && sum(in1) == 1
            plot((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2 ,'r*')
        end
        
        title(['Data Number : ' num2str(Data_index) ', Time Index : ' num2str(time_index)])
        hold off
        axis equal
    end
    
    %% Generate Impact section using inpolygon
    
    % find lateral section when collision point is in ego
    if sum(in2) == 0 && sum(in1) == 1
        if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_x1.x,polygon_x1.y) == 1
            impact_section(Data_index,2) = 1;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_x2.x,polygon_x2.y)==1
            impact_section(Data_index,2) = 2;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_x3.x,polygon_x3.y)==1
            impact_section(Data_index,2) = 3;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_x4.x,polygon_x4.y)==1
            impact_section(Data_index,2) = 4;
        end
        
    elseif sum(in2) == 0 && sum(in1) == 2
        % 점 두개가 각각 x1,x3에 존재할 때 --> x2
        if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                polygon_x2.x,polygon_x2.y) == 1
            impact_section(Data_index,2) = 2;
            
        elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                polygon_x3.x,polygon_x3.y) == 1
            impact_section(Data_index,2) = 3;
            
            % 점 두개가 각각 x1,x1에 존재할 때 --> x1
        elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                polygon_x1.x,polygon_x1.y) == 1
            impact_section(Data_index,2) = 1;
        end
    end
    
    % find longitudinal section when collision point is in ego
    if sum(in2) == 0 && sum(in1) == 1
        if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_1y.x,polygon_1y.y) == 1
            impact_section(Data_index,3) = 1;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_2y.x,polygon_2y.y) == 1
            impact_section(Data_index,3) = 2;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_3y.x,polygon_3y.y) == 1
            impact_section(Data_index,3) = 3;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_4y.x,polygon_4y.y) == 1
            impact_section(Data_index,3) = 4;
            
        elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                polygon_5y.x,polygon_5y.y) == 1
            impact_section(Data_index,3) = 5;
        end
        
    elseif sum(in2) == 0 && sum(in1) == 2
        % ego 점 두개가 각각 5y에 존재할 때
        if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                polygon_5y.x,polygon_5y.y) == 1
            impact_section(Data_index,3) = 5;
            % ego 점 두개가 각각 1y에 존재할 때
        elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                polygon_1y.x,polygon_1y.y) == 1
            impact_section(Data_index,3) = 1;
        end
        
    end
    
    % find lateral section when collision point is in target
    if sum(in1) == 0 && sum(in2) == 1
        if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_x1.x,polygon_x1.y) == 1
            impact_section(Data_index,2) = 1;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_x2.x,polygon_x2.y) == 1
            impact_section(Data_index,2) = 2;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_x3.x,polygon_x3.y) == 1
            impact_section(Data_index,2) = 3;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_x4.x,polygon_x4.y) == 1
            impact_section(Data_index,2) = 4;
            
        end
        
    elseif sum(in1) == 0 && sum(in2)==2
        % target점 두개가 각각 x1,x3에 존재할 때 x2
        if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_x2.x,polygon_x2.y) == 1
            impact_section(Data_index,2) = 2;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_x3.x,polygon_x3.y) == 1
            impact_section(Data_index,2) = 3;
            
            % target 점 두개가 각각 x1,x1에 존재할 때 x1
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_x1.x,polygon_x1.y) == 1
            impact_section(Data_index,2) = 1;
            
            % target 점 두개가 각각 x4,x4에 존재할 때 x4
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_x4.x,polygon_x4.y) == 1
            impact_section(Data_index,2) = 4;
        end
    end
    
    % find longitudinal section when collision point is in target
    if sum(in1) == 0 && sum(in2)==1
        if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_1y.x,polygon_1y.y) == 1
            impact_section(Data_index,3) = 1;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_2y.x,polygon_2y.y) == 1
            impact_section(Data_index,3) = 2;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_3y.x,polygon_3y.y) == 1
            impact_section(Data_index,3) = 3;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_4y.x,polygon_4y.y) == 1
            impact_section(Data_index,3) = 4;
            
        elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                polygon_5y.x,polygon_5y.y) == 1
            impact_section(Data_index,3) = 5;
        end
        
    elseif sum(in1) == 0 && sum(in2) == 2
        % target의 두 개의 중심점이 1~5y 1~5y에 존재할 때
        if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_1y.x,polygon_1y.y) == 1
            impact_section(Data_index,3) = 1;
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_2y.x,polygon_2y.y) == 1
            impact_section(Data_index,3) = 2;
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_3y.x,polygon_3y.y) == 1
            impact_section(Data_index,3) = 3;
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_4y.x,polygon_4y.y) == 1
            impact_section(Data_index,3) = 4;
        elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                (collision_pt_target(3)+collision_pt_target(4))/2,...
                polygon_5y.x,polygon_5y.y) == 1
            impact_section(Data_index,3) = 5;
        end
    end
    
    % 서로 inpolygon 할 때 중심 점을 collision point로 간주
    % find lateral section when collision points are in both ego and target
    if sum(in1) == 1 && sum(in2)==1
        if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_x1.x,polygon_x1.y) == 1
            impact_section(Data_index,2) = 1;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_x2.x,polygon_x2.y) == 1
            impact_section(Data_index,2) = 2;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_x3.x,polygon_x3.y) == 1
            impact_section(Data_index,2) = 3;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_x4.x,polygon_x4.y) == 1
            impact_section(Data_index,2) = 4;
        end
    end
    
    % 서로 inpolygon 할 때 중심 점을 collision point로 간주
    % find longitudinal section when collision points are in both ego and target
    if sum(in1) == 1 && sum(in2) == 1
        if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_1y.x,polygon_1y.y) == 1
            impact_section(Data_index,3) = 1;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_2y.x,polygon_2y.y) == 1
            impact_section(Data_index,3) = 2;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_3y.x,polygon_3y.y) == 1
            impact_section(Data_index,3) = 3;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_4y.x,polygon_4y.y) == 1
            impact_section(Data_index,3) = 4;
            
        elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                (collision_pt_target(2)+collision_pt_ego(2))/2,...
                polygon_5y.x,polygon_5y.y) == 1
            impact_section(Data_index,3) = 5;
        end
    end
    
    %% Exception of Inpolygon
    if impact_sample ~= 0 && (max(in1)+max(in2)==0)
        
        egoPoint(impact_sample,:)= plotSimpleEgoCarGlobal(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, impact_sample),...
            In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y, impact_sample), In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X, impact_sample), [1 1 1 1 1], 1, '-',...
            EGO_CG2_FRONT_BUMPER,EGO_CG2_REAR_BUMPER,EGO_WIDTH/2);
        
        for i_traffic = 1:Traffic_Num
            targetPoint(impact_sample,:) = plotSimpleTargetCarGlobal(Class_B(CLASS_B.MEASURE.GLO_HEADING_ANGLE, i_traffic, impact_sample),...
                Class_B(CLASS_B.MEASURE.GLO_POS_Y, i_traffic, impact_sample), Class_B(CLASS_B.MEASURE.GLO_POS_X, i_traffic, impact_sample) ,[1 1 1 1 1], 1, '-',...
                TARGET_CG2_FRONT_BUMPER,TARGET_CG2_REAR_BUMPER,TARGET_WIDTH/2);
            
            yq1 = targetPoint(impact_sample,1:4); % target points - Global Y
            xq1 = targetPoint(impact_sample,5:8); % target points - Global X
            
            yq2 = egoPoint(impact_sample,1:4); % ego points - Global Y
            xq2 = egoPoint(impact_sample,5:8); % ego points - Global X
            
            yv1=[yq1 yq1(1)]; % target polygon
            xv1=[xq1 xq1(1)];
            
            yv2=[yq2 yq2(1)]; % ego polygon
            xv2=[xq2 xq2(1)];
            
            [in1, on1]=inpolygon(xq2,yq2,xv1,yv1) ; % ego pt in target polygon
            [in2, on2]=inpolygon(xq1,yq1,xv2,yv2) ; % target pt in ego polygon
            
            if max(in1)+max(in2) ~= 0
                break
            elseif impact_sample == impact_sample && max(in1)+max(in2) == 0
                P=[xq1' yq1'];
                PQ = [xq2' yq2'];
            end
        end
        
        CMpt11 = [xq2(4), yq2(4)];
        CMpt15 = [xq2(1), yq2(1)];
        CMpt61 = [xq2(3), yq2(3)];
        CMpt65 = [xq2(2), yq2(2)];
        
        CMpt12 = 3/4*CMpt11 + 1/4*CMpt15;
        CMpt13 = 1/2*CMpt11 + 1/2*CMpt15;
        CMpt14 = 1/4*CMpt11 + 3/4*CMpt15;
        
        CMpt62 = 3/4*CMpt61 + 1/4*CMpt65;
        CMpt63 = 2/4*CMpt61 + 2/4*CMpt65;
        CMpt64 = 1/4*CMpt61 + 3/4*CMpt65;
        
        CMpt21 = 4/5*CMpt11 + 1/5*CMpt61;
        CMpt31 = 3/5*CMpt11 + 2/5*CMpt61;
        CMpt41 = 2/5*CMpt11 + 3/5*CMpt61;
        CMpt51 = 1/5*CMpt11 + 4/5*CMpt61;
        
        CMpt25 = 4/5*CMpt15 + 1/5*CMpt65;
        CMpt35 = 3/5*CMpt15 + 2/5*CMpt65;
        CMpt45 = 2/5*CMpt15 + 3/5*CMpt65;
        CMpt55 = 1/5*CMpt15 + 4/5*CMpt65;
        
        
        % 원본
        centerPtEgo = 1/2*CMpt11 + 1/2*CMpt65; % not CG, center of polygon
        
        interval_Target2centerPtEgo_x = xq1 - centerPtEgo(1);
        interval_Target2centerPtEgo_y = yq1 - centerPtEgo(2);
        dist_Target2centerPtEgo = interval_Target2centerPtEgo_x.^2 +...
            interval_Target2centerPtEgo_y.^2;
        [dist_Target2centerPtEgo_min, dist_Target2centerPtEgo_min_index]=...
            min(dist_Target2centerPtEgo);
        
        impact_Pt_prediction = ...
            [xq1(dist_Target2centerPtEgo_min_index) ...
            yq1(dist_Target2centerPtEgo_min_index)];
        
        centerPt_CM = zeros([14 2]); % 14 : total number of collision mode, 2 : [x, y]
        
        centerPt_CM(1,:)  = 1/2.*CMpt21 + 1/2.*CMpt12;   % centerPt_CM11
        centerPt_CM(2,:)  = 3/4.*CMpt31 + 1/4.*CMpt13;   % centerPt_CM21
        centerPt_CM(3,:)  = 5/6*CMpt41 + 1/6*CMpt14;   % centerPt_CM31
        centerPt_CM(4,:)  = 7/8*CMpt51 + 1/8*CMpt15;   % centerPt_CM41
        centerPt_CM(5,:)  = 7/8*CMpt61 + 1/8*CMpt25;   % centerPt_CM51
        
        centerPt_CM(6,:)  = (CMpt21 + CMpt14)/2;       % centerPt_CM12
        centerPt_CM(7,:)  = (CMpt51 + CMpt64)/2;       % centerPt_CM52
        
        centerPt_CM(8,:)  = 1/2*CMpt25 + 1/2*CMpt12;   % centerPt_CM13
        centerPt_CM(9,:)  = 1/2*CMpt62 + 1/2*CMpt55;   % centerPt_CM53
        
        centerPt_CM(10,:)  = 1/2*CMpt14 + 1/2*CMpt25;  % centerPt_CM14
        centerPt_CM(11,:)  = 3/4*CMpt35 + 1/4*CMpt13;  % centerPt_CM24
        centerPt_CM(12,:) = 5/6*CMpt45 + 1/6*CMpt12;   % centerPt_CM34
        centerPt_CM(13,:) = 7/8*CMpt55 + 1/8*CMpt11;   % centerPt_CM44
        centerPt_CM(14,:) = 1/2*CMpt55 + 1/2*CMpt64;   % centerPt_CM54
        
        interval_Pt2centerPt_CM_x = centerPt_CM(:,1) - impact_Pt_prediction(1);
        interval_Pt2centerPt_CM_y = centerPt_CM(:,2) - impact_Pt_prediction(2);
        dist_Pt2centerPt_CM = interval_Pt2centerPt_CM_x.^2 + ...
            interval_Pt2centerPt_CM_y.^2;
        [dist_Pt2centerPt_CM_min, dist_Pt2centerPt_CM_min_index] = ...
            min(dist_Pt2centerPt_CM);
        
        centerPt_CM_prediction = centerPt_CM(dist_Pt2centerPt_CM_min_index,:);
        
        
        figure()
        plot(xv1,yv1) % target polygon
        hold on
        plot(xv2, yv2) % ego polygon
        
        line([CMpt12(1),CMpt62(1)],[CMpt12(2),CMpt62(2)],'Color','k')
        line([CMpt13(1),CMpt63(1)],[CMpt13(2),CMpt63(2)],'Color','k')
        line([CMpt14(1),CMpt64(1)],[CMpt14(2),CMpt64(2)],'Color','k')
        line([CMpt21(1),CMpt25(1)],[CMpt21(2),CMpt25(2)],'Color','k')
        line([CMpt31(1),CMpt35(1)],[CMpt31(2),CMpt35(2)],'Color','k')
        line([CMpt41(1),CMpt45(1)],[CMpt41(2),CMpt45(2)],'Color','k')
        line([CMpt51(1),CMpt55(1)],[CMpt51(2),CMpt55(2)],'Color','k')
        
        %             plot(centerPt_CM(1,1), centerPt_CM(1,2), 'kx') % centerPt_CM11
        %             plot(centerPt_CM(2,1), centerPt_CM(2,2), 'kx') % centerPt_CM21
        %             plot(centerPt_CM(3,1), centerPt_CM(3,2), 'kx') % centerPt_CM31
        %             plot(centerPt_CM(4,1), centerPt_CM(4,2), 'kx') % centerPt_CM41
        %             plot(centerPt_CM(5,1), centerPt_CM(5,2), 'kx') % centerPt_CM51
        %             plot(centerPt_CM(6,1), centerPt_CM(6,2), 'kx') % centerPt_CM12
        %             plot(centerPt_CM(7,1), centerPt_CM(7,2), 'kx') % centerPt_CM52
        %             plot(centerPt_CM(8,1), centerPt_CM(8,2), 'kx') % centerPt_CM13
        %             plot(centerPt_CM(9,1), centerPt_CM(9,2), 'kx') % centerPt_CM53
        %             plot(centerPt_CM(10,1), centerPt_CM(10,2), 'kx') % centerPt_CM14
        %             plot(centerPt_CM(11,1), centerPt_CM(11,2), 'kx') % centerPt_CM24
        %             plot(centerPt_CM(12,1), centerPt_CM(12,2), 'kx') % centerPt_CM34
        %             plot(centerPt_CM(13,1), centerPt_CM(13,2), 'kx') % centerPt_CM44
        %             plot(centerPt_CM(14,1), centerPt_CM(14,2), 'kx') % centerPt_CM54
        
        
        title(['Exceptional case, Data Number : ' num2str(Data_index) ', Impact Sample : ' num2str(impact_sample)])
        hold off
        axis equal
        
        if centerPt_CM_prediction == centerPt_CM(1,:) % CM 11
            impact_section(Data_index,2) = 1;
            impact_section(Data_index,3) = 1;
        elseif centerPt_CM_prediction == centerPt_CM(2,:) % CM 21
            impact_section(Data_index,2) = 1;
            impact_section(Data_index,3) = 2;
        elseif centerPt_CM_prediction == centerPt_CM(3,:) % CM 31
            impact_section(Data_index,2) = 1;
            impact_section(Data_index,3) = 3;
        elseif centerPt_CM_prediction == centerPt_CM(4,:) % CM 41
            impact_section(Data_index,2) = 1;
            impact_section(Data_index,3) = 4;
        elseif centerPt_CM_prediction == centerPt_CM(5,:) % CM 51
            impact_section(Data_index,2) = 1;
            impact_section(Data_index,3) = 5;
        elseif centerPt_CM_prediction == centerPt_CM(6,:) % CM 12
            impact_section(Data_index,2) = 2;
            impact_section(Data_index,3) = 1;
        elseif centerPt_CM_prediction == centerPt_CM(7,:)  % CM 52
            impact_section(Data_index,2) = 2;
            impact_section(Data_index,3) = 5;
        elseif centerPt_CM_prediction == centerPt_CM(8,:) % CM 13
            impact_section(Data_index,2) = 3;
            impact_section(Data_index,3) = 1;
        elseif centerPt_CM_prediction == centerPt_CM(9,:) % CM 53
            impact_section(Data_index,2) = 3;
            impact_section(Data_index,3) = 5;
        elseif centerPt_CM_prediction == centerPt_CM(10,:) % CM 14
            impact_section(Data_index,2) = 4;
            impact_section(Data_index,3) = 1;
        elseif centerPt_CM_prediction == centerPt_CM(11,:) % CM 24
            impact_section(Data_index,2) = 4;
            impact_section(Data_index,3) = 2;
        elseif centerPt_CM_prediction == centerPt_CM(12,:) % CM 34
            impact_section(Data_index,2) = 4;
            impact_section(Data_index,3) = 3;
        elseif centerPt_CM_prediction == centerPt_CM(13,:) % CM 44
            impact_section(Data_index,2) = 4;
            impact_section(Data_index,3) = 4;
        elseif centerPt_CM_prediction == centerPt_CM(14,:) % CM 54
            impact_section(Data_index,2) = 4;
            impact_section(Data_index,3) = 5;
        end
    end
    
    if Switch_FOV
        if T00_v(1,i) == 0 && T00_vy(1,i) == 0 && T00_yaw(1,i) == 0 && T00_x(1,i) == 0 && T00_y(1,i) == 0 && rv_acc(1,i) == 0
            impact_section(Data_index,3) = 0;
            impact_section(Data_index,2) = 0;
        end
    end
    
    %% Make impact section
    
    impact_section(Data_index,1) = 10*impact_section(Data_index,3) + impact_section(Data_index,2);
    if impact_sample ~= 0 && (impact_section(Data_index,3) == 0 || impact_section(Data_index,2) == 0)
        impact_prediction(Data_index) = 1;
    end
    
    inpolygon_sample = find(inpolygon_sample_all ~= 0, 1, 'first');
    collisionSampleInfo(Data_index, 1) = impact_sample;
    
    if ~isempty(inpolygon_sample)
        collisionSampleInfo(Data_index, 2) = inpolygon_sample;
    end
    
    collisionSampleInfo(Data_index, 3) = impact_section(Data_index,1);
    
    disp([cur_scenario_selection '시나리오의 ' num2str(Data_index) '번째 데이터의 CM GT 생성 완료'])
    
    %% Calculation distance, time
    
    tmp_time=data.Time.data(end);
    tmp_dist=data.Vhcl_Distance.data(end);
    
    driving_time=driving_time+tmp_time;
    driving_distance=driving_distance+tmp_dist;
    
end


%% Check GT Data
if length(find(impact_sample_all==0)) ==...
        length(find(impact_section(:,1)==0))
    
    if find(impact_sample_all==0) == find(impact_section(:,1)==0)
        disp('----------------------------')
        disp('GT Data is saved COMPLETELY!')
        disp('----------------------------')
    else
        disp('---------------------------------------------------')
        disp('The count of impact sample and the count of impact section is same')
        disp('But boths are not match...')
        disp('GT Data is saved INCOMPLETELY')
        disp('---------------------------------------------------')
    end
    
else
    disp('---------------------------------------------------------')
    disp('Impact sample and the count of impact section is not same')
    disp(['impact_sample_all : ',num2str(length(find(impact_sample_all~=0)))])
    disp(['count of impact_section : ',num2str(length(find(impact_section(:,1)~=0)))])
    disp('impact_sample is not 0, but impact_section is 0 :')
    disp(num2str(find(impact_section(:,1)==0 & impact_sample_all~=0)))
    disp('GT Data is saved INCOMPLETELY. TT')
    disp('---------------------------------------------------------')
end

safe_on   = length(find(safe_crash_with_AEB==0));
safe_off  = length(find(safe_crash_with_AEB==1));
crash_on  = length(find(safe_crash_with_AEB==2));
crash_off = length(find(safe_crash_with_AEB==3));

%% Annotation checkpoint
safe=length(pre_crash_true)-nnz(pre_crash_true);
Pre_crash=nnz(pre_crash_true);

disp(['safe : ',num2str(safe)])
disp(['Pre crash : ',num2str(Pre_crash)])

Collision_mode=[11 12 13 14 21 31 41 24 34 44 51 52 53 54];
index_CM=zeros(length(Collision_mode),1);
for index_mode=1:length(Collision_mode)
    if ~isempty(find(impact_section(:,1)==Collision_mode(index_mode),1))
        [index_CM(index_mode),~]=...
            size(find(impact_section(:,1)==Collision_mode(index_mode)));
    end
    if nnz(index_CM(index_mode))~=0
        eval(['collision_mode_' num2str(Collision_mode(index_mode))...
            '=index_CM(index_mode)']);
    end
end

disp('  ')
disp('  ')
disp(['GT generator is finished Succesfully at : ', char(datetime('now'))])
end

%% Function plot Ego Car Simple Global
function  carPoint = plotSimpleEgoCarGlobal(varargin)

CG2FrontBumper = varargin{7};
CG2RearBumper = varargin{8};
halfWidth = varargin{9};

h = '-';

carPoint = zeros(1,8);

if size(varargin,2) == 9
    size_factor=varargin{5};
    yaw=varargin{1};
    globalY=varargin{2};
    globalX=varargin{3};
    
    CG2FrontBumper=size_factor*CG2FrontBumper;
    CG2RearBumper=size_factor*CG2RearBumper;
    halfWidth=size_factor*halfWidth;
    
elseif size(h,2)==9
    size_factor=varargin{5};
    yaw=varargin{1};
    globalY=varargin{2};
    globalX=varargin{3};
    
    CG2FrontBumper=size_factor*CG2FrontBumper;
    CG2RearBumper=size_factor*CG2RearBumper;
    halfWidth=size_factor*halfWidth;
    
    facecolor
elseif size(varargin,2)==8
    
end

rotationMatrix = [ cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];

frontLeft = rotationMatrix * [CG2FrontBumper; halfWidth] + [globalX; globalY];
X_FL=frontLeft(1,1);
Y_FL=frontLeft(2,1);

rearLeft = rotationMatrix * [-1*CG2RearBumper; halfWidth] + [globalX; globalY];
X_RL=rearLeft(1,1);
Y_RL=rearLeft(2,1);

rearRight = rotationMatrix * [-1*CG2RearBumper; -halfWidth] + [globalX ; globalY];
X_RR = rearRight(1,1);
Y_RR = rearRight(2,1);

frontRight = rotationMatrix * [CG2FrontBumper; -halfWidth] + [globalX ; globalY];
X_FR = frontRight(1,1);
Y_FR = frontRight(2,1);

carPoint(1,1) = Y_FR;
carPoint(1,2) = Y_RR;
carPoint(1,3) = Y_RL;
carPoint(1,4) = Y_FL;

carPoint(1,5) = X_FR;
carPoint(1,6) = X_RR;
carPoint(1,7) = X_RL;
carPoint(1,8) = X_FL;

end

%% Function plot Target Car Simple Global
function  carPoint = plotSimpleTargetCarGlobal(varargin)

CG2FrontBumper=varargin{7};
CG2RearBumper=varargin{8};
halfWidth =varargin{9};

h='-';

carPoint=zeros(1,8);

if size(varargin,2) == 9
    size_factor=varargin{5};
    yaw=varargin{1};
    globalY=varargin{2};
    globalX=varargin{3};
    
    CG2FrontBumper=size_factor*CG2FrontBumper;
    CG2RearBumper=size_factor*CG2RearBumper;
    halfWidth=size_factor*halfWidth;
    
elseif size(h,2)==9
    size_factor=varargin{5};
    yaw=varargin{1};
    globalY=varargin{2};
    globalX=varargin{3};
    
    CG2FrontBumper=size_factor*CG2FrontBumper;
    CG2RearBumper=size_factor*CG2RearBumper;
    halfWidth=size_factor*halfWidth;
    
    facecolor
elseif size(varargin,2)==8
    
end

rotationMatrix = [ cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];

frontLeft = rotationMatrix * [CG2FrontBumper + CG2RearBumper; halfWidth] + [globalX; globalY];
X_FL=frontLeft(1,1);
Y_FL=frontLeft(2,1);

rearLeft = rotationMatrix * [0; halfWidth] + [globalX; globalY];
X_RL=rearLeft(1,1);
Y_RL=rearLeft(2,1);

rearRight = rotationMatrix * [0; -halfWidth] + [globalX ; globalY];
X_RR = rearRight(1,1);
Y_RR = rearRight(2,1);

frontRight = rotationMatrix * [CG2FrontBumper + CG2RearBumper; -halfWidth] + [globalX ; globalY];
X_FR = frontRight(1,1);
Y_FR = frontRight(2,1);

carPoint(1,1) = Y_FR;
carPoint(1,2) = Y_RR;
carPoint(1,3) = Y_RL;
carPoint(1,4) = Y_FL;

carPoint(1,5) = X_FR;
carPoint(1,6) = X_RR;
carPoint(1,7) = X_RL;
carPoint(1,8) = X_FL;
end
