function [impact_section,pre_crash_true,impact_sample_all,safe_crash_with_AEB,Safe_ON,Safe_OFF,Crash_ON,Crash_OFF,Driving_Time,Driving_Distance,info,Impactspeedresult] = genCollisionGTCar(Data_Path,CarMaker_Project_Path,Cur_Scenario_Selection,Tablename)
    
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
toggle_Test = 0;
%% ACL GT generator
% clearvars -except Data_Path Dir_Save Scenario_Path Cur_Scenario_Selection Tablename
Scenario_Path = [CarMaker_Project_Path '\Data'];

    % GT Create date
    date_time = datestr(now);
    date_time_index = strfind(date_time,' ');
    
    % Parameter space load
    Parameter_Space =  Tablename;

    num=height(Parameter_Space(:,1));
    
    
    Scenario_File = fileread([Scenario_Path '\TestRun\' Cur_Scenario_Selection]);
    
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
    
    
    %% GT generator
    
    disp('   ACL GT generator ver 071620')
    disp('  ')
    disp(['   GT generator started  at : ', char(datetime('now'))])
    disp('  ')
    
    disp(['    Scenario : ', Cur_Scenario_Selection])
    disp(['    Data counts of the scenario : ', num2str(num)])
    disp('  ')
    disp('  ')
    
%     Cur_Scenario_Selection='TAAS_Suwon_011612_IGLAD_601a'
%     Tablename= [Cur_Scenario_Selection '_Param_space.csv']

    PATH_Scenario_Folder = [Data_Path '\' Cur_Scenario_Selection];
    
    cd(PATH_Scenario_Folder);
    Param_table = Tablename;

    Variable_array = Param_table.Variables;
    Variable_name = Param_table.Properties.VariableNames;
    %%
    
%     eval(['Variable_array = Param_table_' num2str(Iter_num) '.Variables;'])
%     eval(['Variable_name = Param_table_' num2str(Iter_num) '.Properties.VariableNames;'])
%     eval(['num = height(Param_table_' num2str(Iter_num) ');'])

        
    eval(['Variable_array = Param_table.Variables;'])
    eval(['Variable_name = Param_table.Properties.VariableNames;'])
    eval(['num = height(Param_table);'])
    %% Create Label
    
    Impactspeedresult=zeros(num,1);
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
    Driving_Distance=0;
    Driving_Time=0;
    %% Load scenario data and Calculate points of polygon at impact sample
    
    if toggle_Test == 1 
        num = 1;
    end
    for j = 1 : num
        
        matFile_Name = [Cur_Scenario_Selection '_data_' num2str(Variable_array(j,1)) '.mat'];
        load(matFile_Name)
        
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
        
        for i=impact_sample-30:impact_sample
            
            leftpoint(i,:)= Car_Plot_real2_point(-(Car_Yaw(i)-(pi/2)),...
                Car_ty(i),Car_tx(i),[1 1 1 1 1],1,'-',...
                EGO_CG2_FRONT_BUMPER,EGO_CG2_REAR_BUMPER,EGO_WIDTH/2);
            
            rightpoint(i,:)= Car_Plot_real3_point(-(T00_yaw(i)-(pi/2)),...
                T00_y(i)+TARGET_CG2_REAR_BUMPER*cos(-(T00_yaw(i)-(pi/2))),...
                T00_x(i)+TARGET_CG2_REAR_BUMPER*sin(-(T00_yaw(i)-(pi/2))),[1 1 1 1 1],1,'-',...
                TARGET_CG2_FRONT_BUMPER,TARGET_CG2_REAR_BUMPER,TARGET_WIDTH/2);
            
            xq1=rightpoint(i,1:4); % target points
            yq1=rightpoint(i,5:8);
            
            xq2=leftpoint(i,1:4); % ego points
            yq2=leftpoint(i,5:8);
            
            
            xv1=[xq1 xq1(1)]; % target polygon
            yv1=[yq1 yq1(1)];
            
            xv2=[xq2 xq2(1)]; % ego polygon
            yv2=[yq2 yq2(1)];
            
            
            [in1, on1]=inpolygon(xq2,yq2,xv1,yv1) ; % ego pt in target polygon
            [in2, on2]=inpolygon(xq1,yq1,xv2,yv2) ; % target pt in ego polygon
            
            
            if max(in1)+max(in2)~=0
                
                break
                
            elseif i == impact_sample && max(in1)+max(in2)==0
                
                P=[xq1' yq1'];
                PQ = [xq2' yq2'];
                
            end
        end
        impact_section_sample_all(j)=i;
        
       %% Define points and polygons of collision mode section
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
        elseif sum(in1) ==2
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
        
        %% Visualization : Plot Ego, Target vehicle
        
        if Switch_Plot_ImpactScene == 1
            
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
            
            title(['Data Number : ',num2str(j)])
            hold off
            axis equal
        end
        
        %% Generate Impact section using inpolygon
        if sum(in2) == 0 && sum(in1) ==1
            if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x1.x,polygon_x1.y)==1
                impact_section(j,2) =1;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x2.x,polygon_x2.y)==1
                impact_section(j,2) =2;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_x3.x,polygon_x3.y)==1
                impact_section(j,2) =3;
                
            end
        elseif sum(in2) == 0 && sum(in1) ==2
            % 점 두개가 각각 x1,x3에 존재할 때 --> x2
            if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x2.x,polygon_x2.y)==1
                impact_section(j,2) =2;
                
            % 점 두개가 각각 x1,x1에 존재할 때 --> x1
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_x1.x,polygon_x1.y)==1
                impact_section(j,2) = 1;
            end
        end
        
        
        if sum(in2) == 0 && sum(in1)==1
            
            if inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_1y.x,polygon_1y.y)==1
                impact_section(j,3) = 1;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_2y.x,polygon_2y.y)==1
                impact_section(j,3) = 2;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_3y.x,polygon_3y.y)==1
                impact_section(j,3) = 3;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_4y.x,polygon_4y.y)==1
                impact_section(j,3) = 4;
                
            elseif inpolygon(collision_pt_ego(1),collision_pt_ego(2),...
                    polygon_5y.x,polygon_5y.y)==1
                impact_section(j,3) = 5;
            end
            
        elseif sum(in2) == 0 && sum(in1)==2
            % ego 점 두개가 각각 5y에 존재할 때
            if inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_5y.x,polygon_5y.y)==1
                impact_section(j,3) = 5;
                % ego 점 두개가 각각 1y에 존재할 때
            elseif inpolygon((collision_pt_ego(1)+collision_pt_ego(2))/2,...
                    (collision_pt_ego(3)+collision_pt_ego(4))/2,...
                    polygon_1y.x,polygon_1y.y)==1
                impact_section(j,3) = 1;
            end
            
        end
        
        
        if sum(in1) == 0 && sum(in2)==1
            
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x1.x,polygon_x1.y)==1
                impact_section(j,2) =1;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x2.x,polygon_x2.y)==1
                impact_section(j,2) =2;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_x3.x,polygon_x3.y)==1
                impact_section(j,2) =3;
                
            end
            
        elseif sum(in1) == 0 && sum(in2)==2
            % target점 두개가 각각 x1,x3에 존재할 때 x2
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x2.x,polygon_x2.y)==1
                impact_section(j,2) =2;
                % target 점 두개가 각각 x1,x1에 존재할 때 x1
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x1.x,polygon_x1.y)==1
                impact_section(j,2) =1;
                % target 점 두개가 각각 x3,x3에 존재할 때 x3
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_x3.x,polygon_x3.y)==1
                impact_section(j,2) =3;
                
            end
        end
        
        
        if sum(in1) == 0 && sum(in2)==1
            if inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_1y.x,polygon_1y.y)==1
                impact_section(j,3) = 1;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_2y.x,polygon_2y.y)==1
                impact_section(j,3) = 2;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_3y.x,polygon_3y.y)==1
                impact_section(j,3) = 3;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_4y.x,polygon_4y.y)==1
                impact_section(j,3) = 4;
                
            elseif inpolygon(collision_pt_target(1),collision_pt_target(2),...
                    polygon_5y.x,polygon_5y.y)==1
                impact_section(j,3) = 5;
            end
            
        elseif sum(in1) == 0 && sum(in2)==2
            
            % target의 두 개의 중심점이 1~5y 1~5y에 존재할 때
            if inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_1y.x,polygon_1y.y)==1
                impact_section(j,3) = 1;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_2y.x,polygon_2y.y)==1
                impact_section(j,3) = 2;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_3y.x,polygon_3y.y)==1
                impact_section(j,3) = 3;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_4y.x,polygon_4y.y)==1
                impact_section(j,3) = 4;
            elseif inpolygon((collision_pt_target(1)+collision_pt_target(2))/2,...
                    (collision_pt_target(3)+collision_pt_target(4))/2,...
                    polygon_5y.x,polygon_5y.y)==1
                impact_section(j,3) = 5;
            end
        end
        
        % 서로 inpolygon 할 때 중심 점을 collision point로 간주
        if sum(in1) == 1 && sum(in2)==1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x1.x,polygon_x1.y)==1
                impact_section(j,2) =1;
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x2.x,polygon_x2.y)==1
                impact_section(j,2) =2;
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_x3.x,polygon_x3.y)==1
                impact_section(j,2) =3;
                
            end
        end
        
        
        if sum(in1) == 1 && sum(in2)==1
            if inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_1y.x,polygon_1y.y)==1
                impact_section(j,3) =1;
                
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_2y.x,polygon_2y.y)==1
                impact_section(j,3) =2;
                
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_3y.x,polygon_3y.y)==1
                impact_section(j,3) =3;
                
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_4y.x,polygon_4y.y)==1
                impact_section(j,3) =4;
                
            elseif inpolygon((collision_pt_target(1)+collision_pt_ego(1))/2,...
                    (collision_pt_target(2)+collision_pt_ego(2))/2,...
                    polygon_5y.x,polygon_5y.y)==1
                impact_section(j,3) =5;
                
            end
            
        end
        
        %% Exception of Inpolygon
        if impact_sample ~=0 && (max(in1)+max(in2)==0)
            
            centerPtEgo = 1/2*CMpt11 + 1/2*CMpt64; % not CG, center of polygon
            
            interval_Target2centerPtEgo_x = xq1 - centerPtEgo(1);
            interval_Target2centerPtEgo_y = yq1 - centerPtEgo(2);
            dist_Target2centerPtEgo = interval_Target2centerPtEgo_x.^2 +...
                interval_Target2centerPtEgo_y.^2;
            [dist_Target2centerPtEgo_min, dist_Target2centerPtEgo_min_index]=...
                min(dist_Target2centerPtEgo);
            
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
                impact_section(j,2) = 1;
                impact_section(j,3) = 1;
            elseif centerPt_CM_prediction == centerPt_CM(2,:)
                impact_section(j,2) = 1;
                impact_section(j,3) = 2;
            elseif centerPt_CM_prediction == centerPt_CM(3,:)
                impact_section(j,2) = 1;
                impact_section(j,3) = 3;
            elseif centerPt_CM_prediction == centerPt_CM(4,:)
                impact_section(j,2) = 1;
                impact_section(j,3) = 4;
            elseif centerPt_CM_prediction == centerPt_CM(4,:)
                impact_section(j,2) = 1;
                impact_section(j,3) = 4;
            elseif centerPt_CM_prediction == centerPt_CM(5,:)
                impact_section(j,2) = 1;
                impact_section(j,3) = 5;
            elseif centerPt_CM_prediction == centerPt_CM(6,:)
                impact_section(j,2) = 2;
                impact_section(j,3) = 1;
            elseif centerPt_CM_prediction == centerPt_CM(7,:)
                impact_section(j,2) = 2;
                impact_section(j,3) = 5;
            elseif centerPt_CM_prediction == centerPt_CM(8,:)
                impact_section(j,2) = 3;
                impact_section(j,3) = 1;
            elseif centerPt_CM_prediction == centerPt_CM(9,:)
                impact_section(j,2) = 3;
                impact_section(j,3) = 2;
            elseif centerPt_CM_prediction == centerPt_CM(10,:)
                impact_section(j,2) = 3;
                impact_section(j,3) = 3;
            elseif centerPt_CM_prediction == centerPt_CM(11,:)
                impact_section(j,2) = 3;
                impact_section(j,3) = 4;
            elseif centerPt_CM_prediction == centerPt_CM(12,:)
                impact_section(j,2) = 3;
                impact_section(j,3) = 5;
            end
        end
        if Switch_FOV
            if T00_v(1,i) == 0 && T00_vy(1,i) == 0 && T00_yaw(1,i) == 0 && T00_x(1,i) == 0 && T00_y(1,i) == 0 && rv_acc(1,i) == 0
                impact_section(j,3) = 0;
                impact_section(j,2) = 0;
            end
        end
        %% Make impact section
        
        impact_section(j,1)=10*impact_section(j,3)+impact_section(j,2);
        if impact_sample~=0 && (impact_section(j,3)==0 || impact_section(j,2)==0)
            impact_prediction(j)=1;
        end
        %% Calculation distance, time
        
        tmp_time=data.Time.data(end);
        tmp_dist=data.Vhcl_Distance.data(end);
        
        Driving_Time=Driving_Time+tmp_time;
        Driving_Distance=Driving_Distance+tmp_dist;
        
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
    
    Safe_ON   = length(find(safe_crash_with_AEB==0));
    Safe_OFF  = length(find(safe_crash_with_AEB==1));
    Crash_ON  = length(find(safe_crash_with_AEB==2));
    Crash_OFF = length(find(safe_crash_with_AEB==3));
    
      %% Annotation checkpoint
    safe=length(pre_crash_true)-nnz(pre_crash_true);
    Pre_crash=nnz(pre_crash_true);
    
    disp(['safe : ',num2str(safe)])
    disp(['Pre crash : ',num2str(Pre_crash)])
    
    Collision_mode=[11 12 13 21 31 41 23 33 43 51 52 53];
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
    
%% Function Car plot2
function  leftpoint = Car_Plot_real2_point(varargin)

aaa=varargin{7};
bbb=varargin{8};
trff =varargin{9};

h='-';

leftpoint=zeros(1,8);

if size(varargin,2)==3
    
elseif  size(varargin,2)==4
    
elseif size(varargin,2)==5
    
elseif size(varargin,2)==6
    
elseif size(varargin,2)==9
    size_factor=varargin{5};
    al=varargin{1};
    x=varargin{2};
    y=varargin{3};
    
    aaa=size_factor*aaa;
    bbb=size_factor*bbb;
    trff=size_factor*trff;
    
elseif size(h,2)==9
    size_factor=varargin{5};
    al=varargin{1};
    x=varargin{2};
    y=varargin{3};
    
    aaa=size_factor*aaa;
    bbb=size_factor*bbb;
    trff=size_factor*trff;
    
    facecolor
elseif size(varargin,2)==8
    
end
al=-al;

rt1=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ trff;  aaa] + [y ; x];  x11=rt1(2,1);
y11=rt1(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ trff; -1*bbb] + [y ; x];  x22=rt2(2,1);
y22=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [0.8*trff; -1*bbb] + [y ; x];
x33=rt3(2,1);
y33=rt3(1,1);
rt4=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [0.8*trff;  -bbb] + [y ; x];
x44=rt4(2,1);
y44=rt4(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-0.8*trff;  -bbb] + [y ; x];
x55=rt2(2,1);
y55=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-0.8*trff; -1*bbb] + [y ; x];
x66=rt3(2,1);
y66=rt3(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ -trff; -1*bbb] + [y ; x];
x77=rt2(2,1);
y77=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-trff; aaa] + [y ; x];
x88=rt3(2,1);
y88=rt3(1,1);

leftpoint(1,1)=y11;
leftpoint(1,2)=y22;
leftpoint(1,3)=y77;
leftpoint(1,4)=y88;
leftpoint(1,5)=x11;
leftpoint(1,6)=x22;
leftpoint(1,7)=x77;
leftpoint(1,8)=x88;

end
%% Function Car plot3
function rightpoint = Car_Plot_real3_point(varargin)

aaa=varargin{7};
bbb=varargin{8};
trff =varargin{9};

rightpoint=zeros(1,8);

if size(varargin,2)==3
    
elseif  size(varargin,2)==4
    
elseif size(varargin,2)==5
    
elseif size(varargin,2)==6
    
elseif size(varargin,2)==9
    size_factor=varargin{5};
    al=varargin{1};
    x=varargin{2};
    y=varargin{3};
    
    aaa=size_factor*aaa;
    bbb=size_factor*bbb;
    trff=size_factor*trff;
    
    
elseif size(varargin,2)==9
    size_factor=varargin{5};
    al=varargin{1};
    x=varargin{2};
    y=varargin{3};
    
    aaa=size_factor*aaa;
    bbb=size_factor*bbb;
    trff=size_factor*trff;
    
    facecolor
elseif size(varargin,2)==8
    
end
al=-al;

rt1=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ trff;  aaa] + [y ; x];
x11=rt1(2,1);
y11=rt1(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ trff; -1*bbb] + [y ; x];
x22=rt2(2,1);
y22=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [0.8*trff; -1*bbb] + [y ; x];
x33=rt3(2,1);
y33=rt3(1,1);
rt4=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [0.8*trff;  -bbb] + [y ; x];
x44=rt4(2,1);
y44=rt4(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-0.8*trff;  -bbb] + [y ; x];
x55=rt2(2,1);
y55=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-0.8*trff; -1*bbb] + [y ; x];
x66=rt3(2,1);
y66=rt3(1,1);
rt2=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [ -trff; -1*bbb] + [y ; x];
x77=rt2(2,1);
y77=rt2(1,1);
rt3=[ cos(al) -sin(al); sin(al) cos(al)]*...
    [-trff; aaa] + [y ; x];
x88=rt3(2,1);
y88=rt3(1,1);

rightpoint(1,1)=y11;
rightpoint(1,2)=y22;
rightpoint(1,3)=y77;
rightpoint(1,4)=y88;
rightpoint(1,5)=x11;
rightpoint(1,6)=x22;
rightpoint(1,7)=x77;
rightpoint(1,8)=x88;

end
