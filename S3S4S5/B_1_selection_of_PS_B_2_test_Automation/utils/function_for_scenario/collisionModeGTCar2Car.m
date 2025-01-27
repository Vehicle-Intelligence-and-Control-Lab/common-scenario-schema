function [impactSection, impactSample] = collisionModeGTCar2Car(dataDir, projectDir, scenario, parameterSpace, collisionModeType, flagFOV)
% --- collisionModeGTCar2Car에 대한 도움말 ---
%
% CarMaker의  Car to Car 데이터의 충돌 모드 GT(impact section, impact sample) 생성
%   선정한 시나리오에 대해 데이터 경로, 프로젝트 파일 경로, 선정 시나리오 이름, 파라미터 스페이스를 입력으로 받아 충돌 모드
%   GT를 만듭니다.
%
%   [impactSection, impactSample] = collisionModeGTCar2Car(dataDir, projectDir, scenario, parameterSpace, collisionModeType, flagFOV)
%
%   입력 인수
%       dataDir - folder directory that contains CarMaker data files
%       projectDir - folder directory that contains CarMaker project files
%       scenario - scenario name to create collision mode GT
%       parameterSpace - parameter space corresponding the selected scenario
%       collisionModeType - type of collision mode
%                           collisionModeType = 0 : The width and length of the ego vehicle are segmented into three and five sections, respectively.
%                           collisionModeType = 1 : The width and length of the ego vehicle are segmented into four and five sections, respectively.
%       flagFOV - toggle to select whether or not to apply field of view (FOV) of sensor
%                 flagFOV = 0 : sensor FOV is not applied
%                 flagFOV = 1 : sensor FOV is applied
%
%
%   출력 인수
%       impactSection : impact point of ego vehicle in collision
%       impactSample : frame index in collision
%
%   References:
%   [1] Wisch, Marcus, et al. "Car-to-car accidents at intersections in Europe and identification of use cases for the test and assessment of 
%       respective active vehicle safety systems." 26th International Technical Conference on the Enhanced Safety of Vehicles, Eindhoven, Netherlands. 2019.


%--------------------------------------------------------------------------
%{
% Release Note
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

ver 080623
기존 함수에서 사용하지 않는 output 제거
충돌 모드 종류(3x5, 4x5) 선택 가능하게 수정
센서 FOV 적용 여부 선택 가능하게 수정

ver 103023
1. 아래 변수 선언하는 라인 추가 (Line 224~Line 229)
- list_name_data_mat_sort: 데이터(.mat) 디렉토리 내 데이터 리스트
- list_name_data_mat_missing: 파라미터 스페이스 내 상세시나리오 리스트(list_name_data_mat_paramSpace) 중 디렉토리 내 없는 데이터 리스트
2. list_name_data_mat_missing가 존재하면 코드 중단 라인 추가 (Line 229~Line 235)
3. 'Load data and generate collision mode GT'의 for문에서 데이터 읽는 라인 변경
- 변경 전
 >> load([dataDir '/' scenario '/' scenario '_data_' num2str(Data_index) '.mat'])
- 변경 후
 >> Cur_name_data_mat = list_name_data_mat_sort{Data_index};
 >> load([path_dataDir_mat '/' Cur_name_data_mat])
4. impact_sample+30 > length(sim_time)인 경우, imte_index값이 egoPoint의 길이를 초과하는
경우 발생하여 for-loop의 시작, 끝 값을 아래와 같이 수정 (Line 364)
- 변경 전
 >> for time_index = impact_sample-30:impact_sample+30
- 변경 후
 >> for time_index = max(impact_sample-30,0):min(impact_sample+30,length(sim_time))
    
%}

FIGURE_SWITCH = 0;

EXCEPTION_CASE_DISTANCE_THRESHOLD = 10; % m

num = height(parameterSpace(:,1));

Scenario_File = fileread([projectDir '/Data/TestRun/' scenario]);
Search_Road = char(regexp(Scenario_File,'[^\n]*.rd5[^\n]*','match'));
info.road = Search_Road(strfind(Search_Road,'=')+2:end-1);
Search_Vehicle = char(regexp(Scenario_File,'[^\n]*Vehicle =[^\n]*','match'));
info.vehicle = Search_Vehicle(strfind(Search_Vehicle,'=')+2:end-1);
Vehicle_File = fileread([projectDir '/Data/Vehicle/' info.vehicle]);


% Parameter of Ego Vehicle
Search_OuterSkin = char(regexp(Vehicle_File,'[^\n]*Vehicle.OuterSkin =[^\n]*','match'));
Ego_OuterSkin = (Search_OuterSkin(strfind(Search_OuterSkin,'=')+2:end-1));
Ego_OuterSkin_split = strsplit(Ego_OuterSkin, ' ');
RearLowerLeftPoint_positionX = str2double(Ego_OuterSkin_split{1}); % CarMaker GUI > $#> # 
RearLowerLeftPoint_positionY = str2double(Ego_OuterSkin_split{2});
FrontUpperRightPoint_positionX = str2double(Ego_OuterSkin_split{4});
FrontUpperRightPoint_positionY = str2double(Ego_OuterSkin_split{5});

EGO_WIDTH = abs(FrontUpperRightPoint_positionY - RearLowerLeftPoint_positionY);
EGO_LENGTH = abs(FrontUpperRightPoint_positionX - RearLowerLeftPoint_positionX);

Search_Ego_CG2Rear_Bumper = strtrim(char(regexp(Vehicle_File,'[^\n]*Body.pos =[^\n]*','match')));
eval(['tmp_Ego_CG2Rear_Bumper = [' Search_Ego_CG2Rear_Bumper(strfind(Search_Ego_CG2Rear_Bumper,'=')+2:end) '];']);
EGO_CG2_REAR_BUMPER = tmp_Ego_CG2Rear_Bumper(1,1);
EGO_CG2_FRONT_BUMPER = EGO_LENGTH - EGO_CG2_REAR_BUMPER;

% Parameter of Traffic and Sensor
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

        if strcmp(tmp_Traffic_Name,'T00')
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

% Initialization
impactSample = zeros(num,1);
impactSection = zeros(num,3); % Collision mode


IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE                     = 1;  %      [rad]              Global heading angle
IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X                             = 2;  %      [m]                Global longitudinal position
IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y                             = 3;  %      [m]                Global lateral position
IN_VEHICLE_SENSOR.MEASURE.VEHICLE_SPEED                         = 4;  %      [m/s]              absolute velocity
IN_VEHICLE_SENSOR.MEASURE.LONG_ACC                              = 5;  %      [m/s^2]
IN_VEHICLE_SENSOR.MEASURE.LONG_VEL                              = 6;  %     [m/s]
IN_VEHICLE_SENSOR.MEASURE.LAT_VEL                               = 7;  %     [m/s]
IN_VEHICLE_SENSOR.STATE_NUMBER                                  = length(fieldnames(IN_VEHICLE_SENSOR.MEASURE));



CLASS_B.MEASURE.GLO_HEADING_ANGLE                           = 1;  %      [rad]                                            global 좌표계에서의 heading angle
CLASS_B.MEASURE.GLO_POS_Y                                   = 2;  %      [m]                                             position = 뒷범퍼 중심
CLASS_B.MEASURE.GLO_POS_X                                   = 3;  %      [m]
CLASS_B.MEASURE.GLO_VEL_Y                                   = 4;  %      [m/s]
CLASS_B.MEASURE.GLO_VEL_X                                   = 5;  %      [m/s]
CLASS_B.MEASURE.WIDTH                                       = 6;  %      [m]
CLASS_B.MEASURE.LENGTH                                      = 7;  %      [m]
CLASS_B.MEASURE.CLASSIFICATION                              = 8;
CLASS_B.MEASURE.STATE_NUMBER                                = length(fieldnames(CLASS_B.MEASURE));

CLASS_B.PREPROCESSING.REL_POS_Y                             = 9;
CLASS_B.PREPROCESSING.REL_POS_X                             = 10;
CLASS_B.PREPROCESSING.STATE_NUMBER                          = length(fieldnames(CLASS_B.PREPROCESSING));

CLASS_B.STATE_NUMBER                                        = CLASS_B.MEASURE.STATE_NUMBER + CLASS_B.PREPROCESSING.STATE_NUMBER;


% Check the number of data in data directory
path_dataDir_mat = [dataDir '\' scenario];
dirInfo_dataDir = struct2table(dir([path_dataDir_mat '\*_data_*.mat']));
list_name_data_mat = dirInfo_dataDir.name;
list_name_data_mat_split = cellfun(@(v) strsplit(erase(v,'.mat'),'_') ,list_name_data_mat ,'UniformOutput' ,false);
list_num_data_mat = cellfun(@(v) str2num(v{end}) ,list_name_data_mat_split);
dirInfo_dataDir.numOfdata_mat = list_num_data_mat;
dirInfo_dataDir = sortrows(dirInfo_dataDir,"numOfdata_mat","ascend");

list_name_data_mat_sort = dirInfo_dataDir.name;

% Compare 'list_name_data_mat_sort' with 'list_name_data_mat_paramSpace'
list_name_data_mat_paramSpace = arrayfun(@(v) [scenario '_data_' num2str(v+1) '.mat'] ,parameterSpace.Variation ,'UniformOutput' ,false);
list_name_data_mat_union = [list_name_data_mat_sort ; list_name_data_mat_paramSpace];
list_name_data_mat_interesting = list_name_data_mat_paramSpace;
is_UniqOrComp = cell2mat(cellfun(@(v) sum(strcmp(v,list_name_data_mat_union)) ,list_name_data_mat_interesting ,'UniformOutput' ,false));
list_name_data_mat_missing = list_name_data_mat_interesting(is_UniqOrComp ~= 2);

% Error if there is any missing data
if ~isempty(list_name_data_mat_missing)
    txt_error = ['Data below is missing.' newline strjoin(list_name_data_mat_missing,newline)];
    error(txt_error)
end

% Load data and generate collision mode GT
for Data_index = 1 : num
% for Data_index = 308 : 308
% for Data_index = 30   
Cur_name_data_mat = list_name_data_mat_sort{Data_index};

    % load([dataDir '/' scenario '/' scenario '_data_' num2str(Data_index) '.mat'])
    load([path_dataDir_mat '/' Cur_name_data_mat])
    
    % Initialization
    sim_time = data.Time.data;

    In_Vehicle_Sensor = zeros(IN_VEHICLE_SENSOR.STATE_NUMBER, 1, length(sim_time));
    Class_B = zeros(CLASS_B.STATE_NUMBER, Traffic_Num, length(sim_time));


    % Preprocessing
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE,:) = data.Car_Yaw.data';
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y,:) = data.Car_ty.data';  % Fr0(global)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X,:) = data.Car_tx.data';  % Fr0(global)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.VEHICLE_SPEED,:) = data.Car_v.data'; % wheel velocity
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LONG_ACC,:) = data.Car_ax.data'; % Fr1(body fixed)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LONG_VEL,:) = data.Car_vx.data'; % Fr1(body fixed)
    In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.LAT_VEL,:) = data.Car_vy.data'; % Fr1(body fixed)

    for SIG_Num = 1:Traffic_Num
        VAR_Num = SIG_Num;

        tmp_Traffic_Name = char(Traffic_Name_Cell(1,SIG_Num));

        eval(['Class_B(CLASS_B.MEASURE.GLO_POS_Y,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_ty.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_POS_X,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_tx.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_VEL_Y,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_v_0_y.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_VEL_X,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_v_0_x.data;']); % Fr0 (global)
        eval(['Class_B(CLASS_B.MEASURE.GLO_HEADING_ANGLE,' num2str(SIG_Num) ', :) = data.Traffic_' tmp_Traffic_Name '_rz.data;']); % Fr0 (global)
    end

    for track_number = 1:Traffic_Num

        % relative position
        X_FrontCenter_A = EGO_CG2_FRONT_BUMPER.*cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_X, 1, :);
        Y_FrontCenter_A = EGO_CG2_FRONT_BUMPER.*sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_POS_Y, 1, :);

        X_AB = Class_B(CLASS_B.MEASURE.GLO_POS_X, track_number, :) - X_FrontCenter_A;
        Y_AB = Class_B(CLASS_B.MEASURE.GLO_POS_Y, track_number, :) - Y_FrontCenter_A;

        x_AB = X_AB .* cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Y_AB .* sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :));
        y_AB = -X_AB .* sin(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :)) + Y_AB .* cos(In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.GLO_HEADING_ANGLE, 1, :));

        Class_B(CLASS_B.PREPROCESSING.REL_POS_Y, track_number, :) = y_AB;
        Class_B(CLASS_B.PREPROCESSING.REL_POS_X, track_number, :) = x_AB;
    end


    % FOV 적용
    if flagFOV
        for i_sensor = 1:Sensor_Num
            eval(['sensor' num2str(i_sensor) 'Detected = data.Sensor_Object_' char(Sensor_Name_Cell(1,i_sensor)) '_relvTgt_dtct.data;'])
        end

        for time_index = 1:length(sim_time)

            tmpDetectedFlag = 0;
            for i_sensor = 1:Sensor_Num
                eval(['tmpDetectedFlag = tmpDetectedFlag + sensor' num2str(i_sensor) 'Detected(' num2str(time_index) ');'])
            end

            if tmpDetectedFlag == 0                
                Class_B(:, :, time_index) = zeros(CLASS_B.STATE_NUMBER, Traffic_Num, 1);
            end
        end
    end

    AEB_active = data.LongCtrl_AEB_IsActive.data;

    ImpactHVSpeed = zeros(length(sim_time),1);

    inpolygon_sample_all = zeros(length(sim_time),1);

    for time_index = 1:length(sim_time)
        if data.Sensor_Collision_Vhcl_Fr1_Count.data(time_index) > 0
            ImpactHVSpeed(time_index) = In_Vehicle_Sensor(IN_VEHICLE_SENSOR.MEASURE.VEHICLE_SPEED, time_index);
        end
    end

    Impactspeedresult(Data_index) = max(ImpactHVSpeed);

    ImpactHVSpeed = ImpactHVSpeed';
    [~,impact_sample,imv] = find(ImpactHVSpeed,1);

    if Impactspeedresult(Data_index) ~= 0
        pre_crash_true(Data_index) = 1;
    else
        pre_crash_true(Data_index) = 0;
    end

    AEB_on(Data_index) = max(AEB_active);

    if pre_crash_true(Data_index) ~= 0 && AEB_on(Data_index) ~= 0        %AEB on,  Crash
        safe_crash_with_AEB(Data_index) = 2;
    elseif pre_crash_true(Data_index) ~=0 && AEB_on(Data_index) == 0    %AEB OFF, Crash
        safe_crash_with_AEB(Data_index) = 3;
    elseif pre_crash_true(Data_index) == 0 && AEB_on(Data_index) ~= 0    %AEB on,  Safe
        safe_crash_with_AEB(Data_index) = 0;
    else                                           %AEB OFF, Safe
        safe_crash_with_AEB(Data_index) = 1;
    end

    if ~isempty(impact_sample)
        impactSample(Data_index) = impact_sample;
    end

    if isempty(impact_sample)
        disp([num2str(Data_index) '번째 데이터의 CM GT 생성 완료'])
        continue
    end

    time_index_collision_in_for_loop = 0;
    track_number_collsion_in_for_loop = 0;
    
    for time_index = max(impact_sample-30,0):min(impact_sample+30,length(sim_time))

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
                time_index_collision_in_for_loop = time_index;
                track_number_collsion_in_for_loop = i_traffic;
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

    if collisionModeType == 0 % CM 3x5
        CMpt11 = [xq2(4), yq2(4)];
        CMpt14 = [xq2(1), yq2(1)];
        CMpt61 = [xq2(3), yq2(3)];
        CMpt64 = [xq2(2), yq2(2)];

        CMpt12 = 2/3*CMpt11 + 1/3*CMpt14;
        CMpt13 = 1/3*CMpt11 + 2/3*CMpt14;

        CMpt62 = 2/3*CMpt61 + 1/3*CMpt64;
        CMpt63 = 1/3*CMpt61 + 2/3*CMpt64;

        CMpt21 = 4/5*CMpt11 + 1/5*CMpt61;
        CMpt31 = 3/5*CMpt11 + 2/5*CMpt61;
        CMpt41 = 2/5*CMpt11 + 3/5*CMpt61;
        CMpt51 = 1/5*CMpt11 + 4/5*CMpt61;

        CMpt24 = 4/5*CMpt14 + 1/5*CMpt64;
        CMpt34 = 3/5*CMpt14 + 2/5*CMpt64;
        CMpt44 = 2/5*CMpt14 + 3/5*CMpt64;
        CMpt54 = 1/5*CMpt14 + 4/5*CMpt64;

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

        polygon_1y.x = [CMpt11(1) CMpt21(1) CMpt24(1) CMpt14(1) CMpt11(1)];
        polygon_1y.y = [CMpt11(2) CMpt21(2) CMpt24(2) CMpt14(2) CMpt11(2)];

        polygon_2y.x = [CMpt21(1) CMpt31(1) CMpt34(1) CMpt24(1) CMpt21(1)];
        polygon_2y.y = [CMpt21(2) CMpt31(2) CMpt34(2) CMpt24(2) CMpt21(2)];

        polygon_3y.x = [CMpt31(1) CMpt41(1) CMpt44(1) CMpt34(1) CMpt31(1)];
        polygon_3y.y = [CMpt31(2) CMpt41(2) CMpt44(2) CMpt34(2) CMpt31(2)];

        polygon_4y.x = [CMpt41(1) CMpt51(1) CMpt54(1) CMpt44(1) CMpt41(1)];
        polygon_4y.y = [CMpt41(2) CMpt51(2) CMpt54(2) CMpt44(2) CMpt41(2)];

        polygon_5y.x = [CMpt51(1) CMpt61(1) CMpt64(1) CMpt54(1) CMpt51(1)];
        polygon_5y.y = [CMpt51(2) CMpt61(2) CMpt64(2) CMpt54(2) CMpt51(2)];


        if Data_index == 24
            a = 1;
        end

        if time_index == 471

            a = 1;
        end
        if FIGURE_SWITCH == 1

            figure()
            plot(xv1,yv1) % target polygon
            hold on
            plot(xv2, yv2) % ego polygon

            line([CMpt12(1),CMpt62(1)],[CMpt12(2),CMpt62(2)],'Color','k')
            line([CMpt13(1),CMpt63(1)],[CMpt13(2),CMpt63(2)],'Color','k')
            line([CMpt21(1),CMpt24(1)],[CMpt21(2),CMpt24(2)],'Color','k')
            line([CMpt31(1),CMpt34(1)],[CMpt31(2),CMpt34(2)],'Color','k')
            line([CMpt41(1),CMpt44(1)],[CMpt41(2),CMpt44(2)],'Color','k')
            line([CMpt51(1),CMpt54(1)],[CMpt51(2),CMpt54(2)],'Color','k')

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
                impactSection(Data_index,2) = 1;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x2.x,polygon_x2.y)==1
                impactSection(Data_index,2) = 2;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x3.x,polygon_x3.y)==1
                impactSection(Data_index,2) = 3;
            end

        elseif sum(in2) == 0 && sum(in1) == 2
            % 점 두개가 각각 x1,x3에 존재할 때 --> x2
            if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

                % 점 두개가 각각 x1,x1에 존재할 때 --> x1
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;
            end
        end

        % find longitudinal section when collision point is in ego
        if sum(in2) == 0 && sum(in1) == 1
            if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end

        elseif sum(in2) == 0 && sum(in1) == 2
            % ego 점 두개가 각각 5y에 존재할 때
            if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
                % ego 점 두개가 각각 1y에 존재할 때
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;
            end

        end

        % find lateral section when collision point is in target
        if sum(in1) == 0 && sum(in2) == 1
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;
            end

        elseif sum(in1) == 0 && sum(in2)==2
            % target점 두개가 각각 x1,x3에 존재할 때 x2
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

                % target 점 두개가 각각 x1,x1에 존재할 때 x1
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

                % target 점 두개가 각각 x3,x3에 존재할 때 x3
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;
            end
        end

        % find longitudinal section when collision point is in target
        if sum(in1) == 0 && sum(in2)==1
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end

        elseif sum(in1) == 0 && sum(in2) == 2
            % target의 두 개의 중심점이 1~5y 1~5y에 존재할 때
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end
        end

        % 서로 inpolygon 할 때 중심 점을 collision point로 간주
        % find lateral section when collision points are in both ego and target
        if sum(in1) == 1 && sum(in2)==1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;
            end
        end

        % 서로 inpolygon 할 때 중심 점을 collision point로 간주
        % find longitudinal section when collision points are in both ego and target
        if sum(in1) == 1 && sum(in2) == 1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
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
            CMpt14 = [xq2(1), yq2(1)];
            CMpt61 = [xq2(3), yq2(3)];
            CMpt64 = [xq2(2), yq2(2)];

            CMpt12 = 2/3*CMpt11 + 1/3*CMpt14;
            CMpt13 = 1/3*CMpt11 + 2/3*CMpt14;

            CMpt62 = 2/3*CMpt61 + 1/3*CMpt64;
            CMpt63 = 1/3*CMpt61 + 2/3*CMpt64;

            CMpt21 = 4/5*CMpt11 + 1/5*CMpt61;
            CMpt31 = 3/5*CMpt11 + 2/5*CMpt61;
            CMpt41 = 2/5*CMpt11 + 3/5*CMpt61;
            CMpt51 = 1/5*CMpt11 + 4/5*CMpt61;

            CMpt24 = 4/5*CMpt14 + 1/5*CMpt64;
            CMpt34 = 3/5*CMpt14 + 2/5*CMpt64;
            CMpt44 = 2/5*CMpt14 + 3/5*CMpt64;
            CMpt54 = 1/5*CMpt14 + 4/5*CMpt64;

            if FIGURE_SWITCH
                figure()
                plot(xv1,yv1) % target polygon
                hold on
                plot(xv2, yv2) % ego polygon

                line([CMpt12(1),CMpt62(1)],[CMpt12(2),CMpt62(2)],'Color','k')
                line([CMpt13(1),CMpt63(1)],[CMpt13(2),CMpt63(2)],'Color','k')
                line([CMpt21(1),CMpt24(1)],[CMpt21(2),CMpt24(2)],'Color','k')
                line([CMpt31(1),CMpt34(1)],[CMpt31(2),CMpt34(2)],'Color','k')
                line([CMpt41(1),CMpt44(1)],[CMpt41(2),CMpt44(2)],'Color','k')
                line([CMpt51(1),CMpt54(1)],[CMpt51(2),CMpt54(2)],'Color','k')

                title(['Data Number : ' num2str(Data_index) ', Impact Sample : ' num2str(impact_sample)])
                hold off
                axis equal
            end


            % 원본
            centerPtEgo = 1/2*CMpt11 + 1/2*CMpt64; % not CG, center of polygon

            interval_Target2centerPtEgo_x = xq1 - centerPtEgo(1);
            interval_Target2centerPtEgo_y = yq1 - centerPtEgo(2);
            dist_Target2centerPtEgo = interval_Target2centerPtEgo_x.^2 +...
                interval_Target2centerPtEgo_y.^2;
            [dist_Target2centerPtEgo_min, dist_Target2centerPtEgo_min_index]=...
                min(dist_Target2centerPtEgo);

            if dist_Target2centerPtEgo_min <= EXCEPTION_CASE_DISTANCE_THRESHOLD
                impact_Pt_prediction = ...
                    [xq1(dist_Target2centerPtEgo_min_index) ...
                    yq1(dist_Target2centerPtEgo_min_index)];

                centerPt_CM = zeros([12 2]);

                centerPt_CM(1,:)  = 1/2*CMpt21 + 1/2*CMpt12;   % centerPt_CM11
                centerPt_CM(2,:)  = 3/4*CMpt31 + 1/4*CMpt13;   % centerPt_CM21
                centerPt_CM(3,:)  = 5/6*CMpt41 + 1/6*CMpt14;   % centerPt_CM31
                centerPt_CM(4,:)  = 5/6*CMpt51 + 1/6*CMpt24;   % centerPt_CM41
                centerPt_CM(5,:)  = 5/6*CMpt61 + 1/6*CMpt34;   % centerPt_CM51

                centerPt_CM(6,:)  = (CMpt21 + CMpt14)/2;       % centerPt_CM12
                centerPt_CM(7,:)  = (CMpt61 + CMpt54)/2;       % centerPt_CM52

                centerPt_CM(8,:)  = 1/2*CMpt24 + 1/2*CMpt13;   % centerPt_CM13
                centerPt_CM(9,:)  = 3/4*CMpt34 + 1/4*CMpt12;   % centerPt_CM23
                centerPt_CM(10,:) = 5/6*CMpt44 + 1/6*CMpt11;   % centerPt_CM33
                centerPt_CM(11,:) = 5/6*CMpt54 + 1/6*CMpt21;   % centerPt_CM43
                centerPt_CM(12,:) = 5/6*CMpt64 + 1/6*CMpt31;   % centerPt_CM53

                interval_Pt2centerPt_CM_x = centerPt_CM(:,1) - impact_Pt_prediction(1);
                interval_Pt2centerPt_CM_y = centerPt_CM(:,2) - impact_Pt_prediction(2);
                dist_Pt2centerPt_CM = interval_Pt2centerPt_CM_x.^2 + ...
                    interval_Pt2centerPt_CM_y.^2;
                [dist_Pt2centerPt_CM_min, dist_Pt2centerPt_CM_min_index] = ...
                    min(dist_Pt2centerPt_CM);

                centerPt_CM_prediction = centerPt_CM(dist_Pt2centerPt_CM_min_index,:);

                if centerPt_CM_prediction == centerPt_CM(1,:)
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(2,:)
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 2;
                elseif centerPt_CM_prediction == centerPt_CM(3,:)
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 3;
                elseif centerPt_CM_prediction == centerPt_CM(4,:)
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 4;
                elseif centerPt_CM_prediction == centerPt_CM(5,:)
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 5;
                elseif centerPt_CM_prediction == centerPt_CM(6,:)
                    impactSection(Data_index,2) = 2;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(7,:)
                    impactSection(Data_index,2) = 2;
                    impactSection(Data_index,3) = 5;
                elseif centerPt_CM_prediction == centerPt_CM(8,:)
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(9,:)
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 2;
                elseif centerPt_CM_prediction == centerPt_CM(10,:)
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 3;
                elseif centerPt_CM_prediction == centerPt_CM(11,:)
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 4;
                elseif centerPt_CM_prediction == centerPt_CM(12,:)
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 5;
                end
            end
        end

    else % CM 4x5
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


        if FIGURE_SWITCH == 1

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
                impactSection(Data_index,2) = 1;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x2.x,polygon_x2.y)==1
                impactSection(Data_index,2) = 2;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x3.x,polygon_x3.y)==1
                impactSection(Data_index,2) = 3;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x4.x,polygon_x4.y)==1
                impactSection(Data_index,2) = 4;
            end

        elseif sum(in2) == 0 && sum(in1) == 2
            % 점 두개가 각각 x1,x3에 존재할 때 --> x2
            if ( inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x2.x,polygon_x2.y) == 1 ) &&...
                    ( inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x3.x,polygon_x3.y) == 1 )

                if Class_B(CLASS_B.PREPROCESSING.REL_POS_Y, track_number_collsion_in_for_loop, time_index_collision_in_for_loop) > 0
                    impactSection(Data_index,2) = 2;
                elseif Class_B(CLASS_B.PREPROCESSING.REL_POS_Y, track_number_collsion_in_for_loop, time_index_collision_in_for_loop) < 0
                    impactSection(Data_index,2) = 3;
                else
                    rng('default')
                    impactSection(Data_index,2) = datasample([2, 3], 1);
                end

            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x2.x,polygon_x2.y) == 1

                impactSection(Data_index,2) = 2;

            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x3.x,polygon_x3.y) == 1

                impactSection(Data_index,2) = 3;

                % 점 두개가 각각 x1,x1에 존재할 때 --> x1
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x1.x,polygon_x1.y) == 1

                impactSection(Data_index,2) = 1;
            end
        end

        % find longitudinal section when collision point is in ego
        if sum(in2) == 0 && sum(in1) == 1
            if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end

        elseif sum(in2) == 0 && sum(in1) == 2
            % ego 점 두개가 각각 5y에 존재할 때
            if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
                % ego 점 두개가 각각 1y에 존재할 때
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;
            end

        end

        % find lateral section when collision point is in target
        if sum(in1) == 0 && sum(in2) == 1
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x4.x,polygon_x4.y) == 1
                impactSection(Data_index,2) = 4;

            end

        elseif sum(in1) == 0 && sum(in2)==2
            % target점 두개가 각각 x1,x3에 존재할 때 x2
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;

                % target 점 두개가 각각 x1,x1에 존재할 때 x1
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

                % target 점 두개가 각각 x4,x4에 존재할 때 x4
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x4.x,polygon_x4.y) == 1
                impactSection(Data_index,2) = 4;
            end
        end

        % find longitudinal section when collision point is in target
        if sum(in1) == 0 && sum(in2)==1
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end

        elseif sum(in1) == 0 && sum(in2) == 2
            % target의 두 개의 중심점이 1~5y 1~5y에 존재할 때
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
            end
        end

        % 서로 inpolygon 할 때 중심 점을 collision point로 간주
        % find lateral section when collision points are in both ego and target
        if sum(in1) == 1 && sum(in2)==1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x1.x,polygon_x1.y) == 1
                impactSection(Data_index,2) = 1;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x2.x,polygon_x2.y) == 1
                impactSection(Data_index,2) = 2;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x3.x,polygon_x3.y) == 1
                impactSection(Data_index,2) = 3;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x4.x,polygon_x4.y) == 1
                impactSection(Data_index,2) = 4;
            end
        end

        % 서로 inpolygon 할 때 중심 점을 collision point로 간주
        % find longitudinal section when collision points are in both ego and target
        if sum(in1) == 1 && sum(in2) == 1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_1y.x,polygon_1y.y) == 1
                impactSection(Data_index,3) = 1;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_2y.x,polygon_2y.y) == 1
                impactSection(Data_index,3) = 2;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_3y.x,polygon_3y.y) == 1
                impactSection(Data_index,3) = 3;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_4y.x,polygon_4y.y) == 1
                impactSection(Data_index,3) = 4;

            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_5y.x,polygon_5y.y) == 1
                impactSection(Data_index,3) = 5;
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

            if dist_Target2centerPtEgo_min <= EXCEPTION_CASE_DISTANCE_THRESHOLD
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


                if FIGURE_SWITCH
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
                end

                if centerPt_CM_prediction == centerPt_CM(1,:) % CM 11
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(2,:) % CM 21
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 2;
                elseif centerPt_CM_prediction == centerPt_CM(3,:) % CM 31
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 3;
                elseif centerPt_CM_prediction == centerPt_CM(4,:) % CM 41
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 4;
                elseif centerPt_CM_prediction == centerPt_CM(5,:) % CM 51
                    impactSection(Data_index,2) = 1;
                    impactSection(Data_index,3) = 5;
                elseif centerPt_CM_prediction == centerPt_CM(6,:) % CM 12
                    impactSection(Data_index,2) = 2;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(7,:)  % CM 52
                    impactSection(Data_index,2) = 2;
                    impactSection(Data_index,3) = 5;
                elseif centerPt_CM_prediction == centerPt_CM(8,:) % CM 13
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(9,:) % CM 53
                    impactSection(Data_index,2) = 3;
                    impactSection(Data_index,3) = 5;
                elseif centerPt_CM_prediction == centerPt_CM(10,:) % CM 14
                    impactSection(Data_index,2) = 4;
                    impactSection(Data_index,3) = 1;
                elseif centerPt_CM_prediction == centerPt_CM(11,:) % CM 24
                    impactSection(Data_index,2) = 4;
                    impactSection(Data_index,3) = 2;
                elseif centerPt_CM_prediction == centerPt_CM(12,:) % CM 34
                    impactSection(Data_index,2) = 4;
                    impactSection(Data_index,3) = 3;
                elseif centerPt_CM_prediction == centerPt_CM(13,:) % CM 44
                    impactSection(Data_index,2) = 4;
                    impactSection(Data_index,3) = 4;
                elseif centerPt_CM_prediction == centerPt_CM(14,:) % CM 54
                    impactSection(Data_index,2) = 4;
                    impactSection(Data_index,3) = 5;
                end
            end
        end

    end
    

    if flagFOV
        for track_number = 1:Traffic_Num
            if sum( Class_B(:, :, impact_sample), 'all' ) == 0
                impactSection(Data_index,3) = 0;
                impactSection(Data_index,2) = 0;
            end
        end
    end

    %% Make impact section

    impactSection(Data_index,1) = 10*impactSection(Data_index,3) + impactSection(Data_index,2);
    if impact_sample ~= 0 && (impactSection(Data_index,3) == 0 || impactSection(Data_index,2) == 0)
        impact_prediction(Data_index) = 1;
    end

    inpolygon_sample = find(inpolygon_sample_all ~= 0, 1, 'first');
    collisionSampleInfo(Data_index, 1) = impact_sample;

    if ~isempty(inpolygon_sample)
        collisionSampleInfo(Data_index, 2) = inpolygon_sample;
    end

    collisionSampleInfo(Data_index, 3) = impactSection(Data_index,1);

    disp([num2str(Data_index) '번째 데이터의 CM GT 생성 완료'])

    
    

end




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
