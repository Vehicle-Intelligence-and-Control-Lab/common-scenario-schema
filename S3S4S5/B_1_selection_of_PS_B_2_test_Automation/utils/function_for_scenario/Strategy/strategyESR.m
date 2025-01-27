cd([ CarMaker_Project_Path '\src_cm4sl'])

run([Cm4sl_Path '\' Simulink_Model]);                                                                 
CM_Simulink;

Cur_Strategy = 'ESR';
Cur_Strategy_num = 3;

Dir_Original = [ Data_Path '\' Ori_Scenario];
cd(Dir_Original)

% Ori_Param_table=readtable([ Ori_Scenario '_Param_space.csv']);   % Param
% load([Ori_Scenario '_GT.mat']);                                  % GT
Sum_num=[];

for i=1:length(Annotation_Fallback(:,1))
    Sum_num(i,1) = sum(Annotation_Fallback(i,2:end));
end


Fallback_index=find((mod(Sum_num,2)==0)...
 & (Ori_impact_section(:,1)~=0));



Scenario_Path= [CarMaker_Project_Path '\Data'];
Switch_Export_ERG2MAT = 1;
Switch_Plot_ImpactScene = 0;

Variation_fallback = Ori_Param_table(Fallback_index,1);

next_Param_table = Ori_Param_table(Fallback_index,:);
% if Switch_Random_Gen    
%     next_Traffic_route = Traffic_route(Fallback_index,:);
%     next_Traffic_initial_vel = Traffic_initial_vel(Fallback_index,:);
%     next_Traffic_initial_sRoad_pose = Traffic_initial_sRoad_pose(Fallback_index,:);
%     next_Traffic_initial_tRoad_pose = Traffic_initial_tRoad_pose(Fallback_index,:);
% end
cd(Data_Path)
Cur_AES_Scenario_Selection=[Ori_Scenario '_' Cur_Strategy ];
mkdir([Ori_Scenario '_' Cur_Strategy]);

Dir_current     = [Data_Path '\' Ori_Scenario '_' Cur_Strategy];
cd(Dir_current)

writetable(next_Param_table, [ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);

cd([ CarMaker_Project_Path '\src_cm4sl'])



Variable_array = next_Param_table.Variables;
Variable_name = next_Param_table.Properties.VariableNames;
Value_Variation = height(next_Param_table(:,1))


%% ELCL Testrun generation
TestRun_name = Ori_Scenario;

cd([CarMaker_Project_Path '\Data\TestRun'])

% TestRun
TestRun = fileread(TestRun_name);

Search_Ego_Route = char(regexp(TestRun,'[^\n]*.VhclRoute[^\n]*','match'));
Ego_route = str2double(Search_Ego_Route(strfind(Search_Ego_Route,'=')+8:end-1));


% Road
Search_Road = char(regexp(TestRun,'[^\n]*.rd5[^\n]*','match'));
Road_name = Search_Road(strfind(Search_Road,'=')+2:end-1);
Road      = fileread([CarMaker_Project_Path '\Data\Road\' Road_name]);

Search_Max_Route = char(regexp(Road,'[^\n]*.Routes[^\n]*','match'));
Max_Route_num = str2double(Search_Max_Route(strfind(Search_Max_Route,'=')+1:end-1));


% Vehicle
Search_Vehicle = char(regexp(TestRun,'[^\n]*Vehicle =[^\n]*','match'));
Vehicle_name   = Search_Vehicle(strfind(Search_Vehicle,'=')+2:end-1);
Vehicle = fileread([CarMaker_Project_Path '\Data\Vehicle\' Vehicle_name]);


% Traffic
Search_Traffic_number = char(regexp(TestRun,'[^\n]*Traffic.N =[^\n]*','match'));
Traffic_number = Search_Traffic_number(strfind(Search_Traffic_number,'=')+2:end-1);



%%

for j = 1:Value_Variation
%     j=71
    import_param_space = Variable_array(j,:);
    import_data_number = Variable_array(j,1);
    
    %% Fallback Testrun generation
    cd([CarMaker_Project_Path '\Data\TestRun'])
    
    % Traffic data csv generation
    clearvars Traffic_csv_table Time
    load([Dir_Original '\' Ori_Scenario '_data_' num2str(import_data_number+1) '.mat']);
    Time(:,1) = data.Time.data;
    Traffic_csv_table = table(Time);
    
    for Traffic_index = 0 : str2double(Traffic_number)-1
       Search_Traffic_name = char(regexp(TestRun,['[^\n]*Traffic.' num2str(Traffic_index) '.Name =[^\n]*'],'match'));
       Traffic_name = Search_Traffic_name(strfind(Search_Traffic_name,'=')+2:end-1);
       
       eval(['T' num2str(Traffic_index,'%02d') '_tx(:,1) = data.Traffic_' Traffic_name '_tx.data;'])
       eval(['T' num2str(Traffic_index,'%02d') '_ty(:,1) = data.Traffic_' Traffic_name '_ty.data;'])
       eval(['T' num2str(Traffic_index,'%02d') '_tz(:,1) = data.Traffic_' Traffic_name '_tz.data;'])
       
       eval(['T' num2str(Traffic_index,'%02d') '_rx(:,1) = data.Traffic_' Traffic_name '_rx.data;'])
       eval(['T' num2str(Traffic_index,'%02d') '_ry(:,1) = data.Traffic_' Traffic_name '_ry.data;'])
       eval(['T' num2str(Traffic_index,'%02d') '_rz(:,1) = data.Traffic_' Traffic_name '_rz.data;'])
       
       eval(['tmp_Traffic_csv_table=table(T' num2str(Traffic_index,'%02d') '_tx,' 'T' num2str(Traffic_index,'%02d') '_ty,' 'T' num2str(Traffic_index,'%02d') '_tz,'...
           'T' num2str(Traffic_index,'%02d') '_rx,' 'T' num2str(Traffic_index,'%02d') '_ry,' 'T' num2str(Traffic_index,'%02d') '_rz);' ])
        
       Traffic_csv_table = [Traffic_csv_table, tmp_Traffic_csv_table];
       
       eval(['clearvars T' num2str(Traffic_index,'%02d') '_tx ' 'T' num2str(Traffic_index,'%02d') '_ty ' 'T' num2str(Traffic_index,'%02d') '_tz '...
           'T' num2str(Traffic_index,'%02d') '_rx ' 'T' num2str(Traffic_index,'%02d') '_ry ' 'T' num2str(Traffic_index,'%02d') '_rz' ])
       
       clearvars tmp_Traffic_csv_table
       
    end
    
    Traffic_csv_table.Properties.VariableNames(1) = {'#Time'};
    writetable(Traffic_csv_table,[CarMaker_Project_Path '\SimInput\' TestRun_name '_traffic_data_' num2str(import_data_number+1) '.csv']);
    
    
    Search_Ego_Init_Vel = char(regexp(TestRun,'[^\n]*.Init.Velocity = [^\n]*','match'));
    Ego_Init_Vel_Split = strsplit(Search_Ego_Init_Vel,'=');
    Ego_Init_Vel = str2double(char(Ego_Init_Vel_Split(2)));
    
    Search_Ego_Init_Lat_Pos = char(regexp(TestRun,'[^\n]*.Init.LaneOffset = [^\n]*','match'));
    Ego_Init_Lat_Pos_Split = strsplit(Search_Ego_Init_Lat_Pos,'=');
    Ego_Init_Lat_Pos = str2double(char(Ego_Init_Lat_Pos_Split(2)));
    
    Search_Ego_LongDyn = char(regexp(TestRun,'[^\n]*DrivMan.0.LongDyn = [^\n]*','match'));
    Ego_LongDyn_Split  = strsplit(Search_Ego_LongDyn,'LongDyn = ');
    Ego_LongDyn        = Ego_LongDyn_Split(2);
    
    % Testrun generation    
    n=ifile_new;
    ifile_read(n, TestRun_name);
    
    ifile_setstr(n,'Traffic.IFF.FName',[CarMaker_Project_Path '\SimInput\' TestRun_name '_traffic_data_' num2str(import_data_number+1) '.csv']);
    ifile_setstr(n,'Traffic.IFF.Time.Name','Time');
        
    ifile_setstr(n,'DrivMan.0.EndCondition', 'LongCtrl.AEB.IsActive > 0');
    ifile_setstr(n,'DrivMan.1.TimeLimit', '0.55');
    ifile_setstr(n,'DrivMan.1.LongDyn',  deblank(char(Ego_LongDyn)));
    ifile_setstr(n,'DrivMan.1.LatDyn', ['Driver ' num2str(Ego_Init_Lat_Pos-0.9)]);
    
    
    ifile_setstr(n,'DrivMan.2.TimeLimit', '5');
    ifile_setstr(n,'DrivMan.2.EndCondition', 'Car.v < 0.1');
    ifile_setstr(n,'DrivMan.2.LongDyn', 'Stop 6 0');
    ifile_setstr(n,'DrivMan.2.LatDyn', ['Driver ' num2str(Ego_Init_Lat_Pos-0.9)]);
    
    
    for Traffic_index = 0 : str2double(Traffic_number)-1
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.FreeMotion'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tx.Name'],['T' num2str(Traffic_index,'%02d') '_tx']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tx.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tx.Offset'],'0');
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ty.Name'],['T' num2str(Traffic_index,'%02d') '_ty']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ty.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ty.Offset'],'0');
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tz.Name'],['T' num2str(Traffic_index,'%02d') '_tz']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tz.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_tz.Offset'],'0');
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rx.Name'],['T' num2str(Traffic_index,'%02d') '_rx']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rx.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rx.Offset'],'0');
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ry.Name'],['T' num2str(Traffic_index,'%02d') '_ry']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ry.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_ry.Offset'],'0');
        
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rz.Name'],['T' num2str(Traffic_index,'%02d') '_rz']);
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rz.Factor'],'1');
        ifile_setstr(n,['Traffic.' num2str(Traffic_index) '.IFF.FM_rz.Offset'],'0');
                        
    end
    
    ifile_setstr(n,'DrivMan.nDMan','3');

    ifile_write(n, [TestRun_name '_' Cur_Strategy ]);
    ifile_delete(n);
    
    
    %Random car generation
    
%     if Switch_Random_Gen
%         cd(Dir_Code)
%         
%         
%         Ego_velocity = Param_table.vA(import_data_number+1);
%         Cut_in_dist  = Param_table.dx(import_data_number+1);
%         
%         genRandomCar;
%         
%     end
    cd([ CarMaker_Project_Path '\src_cm4sl'])

    cmguicmd(['LoadTestRun ' Cur_AES_Scenario_Selection ]);                                   %Load a TestRun
    disp('TestRun loaded');
    
    for a = 2:length(import_param_space)
        
        Val_name = char(Variable_name(a));
        
        NValueCmd = ['NamedValue set ' Val_name ' ' ,num2str(import_param_space(1,a),'%d')];
        cmguicmd(NValueCmd);
    end
    
            cmguicmd(['SetResultFName "../Data/Mat/%f/Variation ' num2str(import_data_number) '"']);

    
    NValueCmd_DN = ['NamedValue set DN ',num2str(import_data_number,'%d')];
    cmguicmd(NValueCmd_DN);
    
    % Fallback_TTC
%     NValueCmd_Fallback_TTC = ['NamedValue set Fallback_TTC ',num2str(Fallback_TTC,'%d')];
%     cmguicmd(NValueCmd_Fallback_TTC);
    
    cmguicmd('StartSim',0); %Start the Simulation with a timeout of 0s
    
    disp(['Simulation Started Data Number is ' num2str(import_data_number)]);
    
    pause(7)    %Set Matlab wait until the preparation phase of CM is finished
    
    while 1
        if strcmp(get_param(Simulink_Model, 'SimulationStatus'),'stopped') == 1 %Request and compare simulation status of Matlab Model
            
            cmguicmd('StopSim', 0);  %Stop Simulation
            %                                 clear all;
            break;  %Quit while loop if simulation is stopped
        else
            pause(1) %Wait 1s if the simulation is still running before checking the simulation status again.
            %                                 This is necessary otherwise Matlab would check the status over and
            %                                 over which would impact the simulation speed negatively
        end
    end
end


% delete csv file
cd([CarMaker_Project_Path '\SimInput']);
delete *.csv


%%%% ERG to Mat convert %%%%
    disp('ERG2MAT Start')
    erg2mat(Cur_AES_Scenario_Selection,Variable_array,Data_Path)

% genCollisioin GT
cd(Dir_current)
if isempty(Variable_array)==0
    
    [tmp_impact_section,tmp_pre_crash_true,tmp_impact_sample_all,tmp_safe_crash_with_AEB,tmp_Safe_ON,tmp_Safe_OFF,tmp_Crash_ON,tmp_Crash_OFF,tmp_Driving_Time,tmp_Driving_Distance,tmp_info,tmp_Impactspeedresult]...
        =genCollisionGT(Data_Path,CarMaker_Project_Path,Cur_AES_Scenario_Selection,next_Param_table);
    
    impact_section = tmp_impact_section;
    pre_crash_true = tmp_pre_crash_true;
    impact_sample_all = tmp_impact_sample_all;
    safe_crash_with_AEB = tmp_safe_crash_with_AEB;
    Safe_ON = tmp_Safe_ON;
    Safe_OFF = tmp_Safe_OFF;
    Crash_ON = tmp_Crash_ON;
    Crash_OFF = tmp_Crash_OFF;
    Driving_Time = tmp_Driving_Time;
    Driving_Distance = tmp_Driving_Distance;
    info = tmp_info;
    Impactspeedresult = tmp_Impactspeedresult;
    
    save([Cur_AES_Scenario_Selection '_GT.mat'], ...
        'impact_section' , 'pre_crash_true' ,'impact_sample_all',...
        'safe_crash_with_AEB','Safe_ON','Safe_OFF','Crash_ON','Crash_OFF','Driving_Time','Driving_Distance','info','Impactspeedresult')
end