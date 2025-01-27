cd([ Project_Path '\src_cm4sl'])

run([cm4sl_Path '\' simulink_model]);                                                                 
CM_Simulink;

Cur_Strategy = 'DEC';
Cur_Strategy_num = 1;

Dir_Original = [ Data_Path '\' Ori_Scenario];
cd(Dir_Original)

Ori_Param_table=readtable([ Ori_Scenario '_Param_space.csv']);   % Param
load([Ori_Scenario '_GT.mat']);                                  % GT
Sum_num=[];
for i=1:length(Annotation_Fallback(:,1))
    Sum_num(i,1) = sum(Annotation_Fallback(i,2:end));
end


Fallback_index=find((mod(Sum_num,2)==0)...
 & (impact_section(:,1)==11|impact_section(:,1)==12|impact_section(:,1)==13)|impact_section(:,1)==21|impact_section(:,1)==23);


Scenario_Path= [Project_Path '\Data'];
Switch_Export_ERG2MAT = 1;
Switch_Plot_ImpactScene = 0;

Variation_fallback = Ori_Param_table(Fallback_index,1);


next_Param_table = Ori_Param_table(Fallback_index,:);

if Switch_Random_Gen
    
    next_Traffic_route = Traffic_route(Fallback_index,:);
    next_Traffic_initial_vel = Traffic_initial_vel(Fallback_index,:);
    next_Traffic_initial_sRoad_pose = Traffic_initial_sRoad_pose(Fallback_index,:);
    next_Traffic_initial_tRoad_pose = Traffic_initial_tRoad_pose(Fallback_index,:);
end

cd(Data_Path)
Cur_Scenario_Selection=[Ori_Scenario '_' Cur_Strategy ];
mkdir([Ori_Scenario '_' Cur_Strategy]);

Dir_current     = [Data_Path '\' Ori_Scenario '_' Cur_Strategy];
cd(Dir_current)

writetable(next_Param_table, [ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);

cd([ Project_Path '\src_cm4sl'])


Variable_array = next_Param_table.Variables;
Variable_name = next_Param_table.Properties.VariableNames;
Value_Variation = height(next_Param_table(:,1));

if Switch_test
    Value_Variation=1;
end

for j = 1:Value_Variation
    import_param_space = Variable_array(j,:);
    import_data_number = Variable_array(j,1);
    
       %Random car generation
        if Switch_Random_Gen
            cd(Dir_Code)

            Ego_velocity = Param_table.vA(import_data_number+1);
            Cut_in_dist  = Param_table.dx(import_data_number+1);            
            
            genRandomCar;
            
        end
            cmguicmd(['LoadTestRun ' Cur_Scenario_Selection ]);                                   %Load a TestRun
        disp('TestRun loaded');
        
    for a = 2:length(import_param_space)
        
        Val_name = char(Variable_name(a));
        
        NValueCmd = ['NamedValue set ' Val_name ' ' ,num2str(import_param_space(1,a),'%d')];
        cmguicmd(NValueCmd);
    end
    

    
    NValueCmd_DN = ['NamedValue set DN ',num2str(import_data_number,'%d')];
    cmguicmd(NValueCmd_DN);
    
    % Fallback_TTC
    NValueCmd_Fallback_TTC = ['NamedValue set Fallback_TTC ',num2str(Fallback_TTC,'%d')];
    cmguicmd(NValueCmd_Fallback_TTC);
    
    cmguicmd('StartSim',0); %Start the Simulation with a timeout of 0s
    
    disp(['Simulation Started Data Number is ' num2str(import_data_number)]);
    
    pause(5)    %Set Matlab wait until the preparation phase of CM is finished
    
    while 1
        if strcmp(get_param(simulink_model, 'SimulationStatus'),'stopped') == 1 %Request and compare simulation status of Matlab Model
            
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

cd(Dir_Code)
genCollisionGT_120920