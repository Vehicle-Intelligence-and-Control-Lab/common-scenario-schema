function testAutomation(cur_scenario_selection,param_table,simulink_model,save_path)

%% testAutomation %%
% CarMaker Test Automation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cur_Scenario_Selection
% Variable_array
% Variable_name
% Simulink_model
% toggle_Test

% if toggle_Test
%     Value_Variation=1;
% end
disp('Test Automation Start')

variable_array = param_table.Variables;
variable_name  = param_table.Properties.VariableNames;

[length_variable_array,~] = size(variable_array);
for variation_index = 1:length_variable_array
     
    import_param_space = variable_array(variation_index,:);
    import_data_number = variable_array(variation_index,1);
    
    
    % Load a TestRun
    cmguicmd(['LoadTestRun ' cur_scenario_selection ]);
    disp('Load TestRun ');
    
    for a = 2:length(import_param_space)
        
        val_name = char(variable_name(a));
        
        
        NValueCmd = ['NamedValue set ' val_name ' ' ,num2str(import_param_space(1,a),'%d')];
        cmguicmd(NValueCmd);
    end
    
    replace_save_path = replace(save_path,'\','/');
    cmguicmd(['SetResultFName "' replace_save_path '/Variation ' num2str(import_data_number) '"']);



    cmguicmd('StartSim',0); %Start the Simulation with a timeout of 0s

    disp(['Simulation Started Data Number is ' num2str(import_data_number)]);

    pause(7)    %Set Matlab wait until the preparation phase of CM is finished

    while 1
        if strcmp(get_param(simulink_model, 'SimulationStatus'),'stopped') == 1 %Request and compare simulation status of Matlab Model

            cmguicmd('StopSim', 0);  %Stop Simulation

            break;                   %Quit while loop if simulation is stopped
        else
            pause(1)                 %Wait 1s if the simulation is still running before checking the simulation status again.
            %                         This is necessary otherwise Matlab would check the status over and
            %                         over which would impact the simulation speed negatively
        end
    end

end
end



