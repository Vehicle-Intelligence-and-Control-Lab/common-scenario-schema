function scenario_generation(scenario_generation_path, scenario_name, param_space_path, ...
                        toggle_IDM, toggle_testAutomation, toggle_erg2mat, ...
                        toggle_genCollisionGT, toggle_genCAGT, toggle_movie_export)

    %% Initialization %%
    old_dir = strsplit(path, ';');
    list_idx_IPG = find(contains(old_dir, '\IPG\'));
    arrayfun(@(v) rmpath(old_dir{v}), list_idx_IPG);

    % Scenario setup
    carmaker_project_name = 'CarMaker Project'; % Default
    if toggle_IDM == 1
        matlab_version = version;
        if contains(matlab_version, '2022b')
            simulink_model = 'ACC_with_IDM_ver2022b';
        elseif contains(matlab_version, '2023a')
            simulink_model = 'ACC_with_IDM_ver2023a';
        else
            simulink_model = 'ACC_with_IDM';
        end
        run(fullfile(scenario_generation_path, 'CarMaker Project', 'src_cm4sl', 'parameters_AccelCtrl_ACC_with_IDM.m'));
    else
        simulink_model = 'generic';
    end

    %% Scenario generation
    carmaker_project_path = fullfile(scenario_generation_path, carmaker_project_name);
    mat_path = fullfile(scenario_generation_path, 'Data', 'Mat');                     % Mat 저장 경로
    erg_path = fullfile(scenario_generation_path, 'Data', 'Erg');                       % Erg 저장 경로
    scenairo_function_path = fullfile(scenario_generation_path, 'function_for_scenario');
    
    addpath(scenairo_function_path);

    % CarMaker directory
    testrun_dir = fullfile(carmaker_project_path, 'Data', 'TestRun');
    cm4sl_dir = fullfile(carmaker_project_path, 'src_cm4sl');
    simoutput_dir = fullfile(carmaker_project_path, 'SimOutput');

    % Scenario library
    dinInfo_path_testrunDirectory = struct2table(dir(testrun_dir));
    idx_name_testrun_select = dinInfo_path_testrunDirectory.isdir ~= 1 ...
        & ~contains(dinInfo_path_testrunDirectory.name, 'tmp_') ...
        & ~contains(dinInfo_path_testrunDirectory.name, '.'); 
    testrun_list = dinInfo_path_testrunDirectory.name(idx_name_testrun_select);
    
    for selected_idx = 1:length(testrun_list)
        if strcmp(testrun_list{selected_idx}, scenario_name)
            scenario_selection = testrun_list(selected_idx);
        end
    end

    %% CarMaker Simulation
    cd(cm4sl_dir);
    cmenv; % CarMaker 환경설정
    run(simulink_model);
    CM_Simulink; % CarMaker GUI
    cmcmd('setprojectdir');

    for scenario_index = 1:length(scenario_selection)
        % Read testrun file
        path_vehicleDirectory = fullfile(carmaker_project_path, 'Data', 'Vehicle');
        path_testrunDirectory = fullfile(carmaker_project_path, 'Data', 'Testrun');

        info_testrunFile = fileread(fullfile(path_testrunDirectory, scenario_selection{scenario_index}));
        info_testrunFile_cell = strsplit(info_testrunFile, newline)';

        % Read vehicle file
        idx_info_vehicleFileName = find(contains(info_testrunFile_cell, 'Vehicle = '));
        info_vehicleFileName = deblank(info_testrunFile_cell{idx_info_vehicleFileName});
        info_vehicleFileName_split = strsplit(info_vehicleFileName, ' = ');
        vehicleFileName = info_vehicleFileName_split{end};

        info_vehicleFile = fileread(fullfile(path_vehicleDirectory, vehicleFileName));
        info_vehicleFile_cell = strsplit(info_vehicleFile, newline)';

        cd(cm4sl_dir);
        cur_scenario_selection = char(scenario_selection(scenario_index));
        cur_scenario_erg_save_path = fullfile(erg_path, cur_scenario_selection);
        cur_scenario_mat_save_path = fullfile(mat_path, cur_scenario_selection);

        % Create directories
        mkdir(cur_scenario_erg_save_path);
        mkdir(cur_scenario_mat_save_path);

        % Make Parameter
        param_table = readtable(param_space_path);

        % Save parameter space for server
        writetable(param_table, fullfile(mat_path, cur_scenario_selection, [cur_scenario_selection '_Param_space.csv']));
        variable_array = param_table.Variables;

        if toggle_testAutomation == 1
            tic;
            testAutomation(cur_scenario_selection, param_table, simulink_model, cur_scenario_erg_save_path);
            disp('End Test Automation');
            toc;
        end

        % ERG to Mat convert
        if toggle_erg2mat == 1
            tic;
            disp('ERG2MAT Start');
            erg2mat(cur_scenario_selection, variable_array, cur_scenario_erg_save_path, cur_scenario_mat_save_path);
            toc;
        end

        % GT annotation
        if toggle_genCollisionGT == 1 % Car
            tic;
            [impact_section, pre_crash_true, impact_sample_all, safe_crash_with_AEB, ...
                safe_on, safe_off, crash_on, crash_off, driving_time, driving_distance, ...
                info, impact_speed] = genCollisionGTCar(mat_path, carmaker_project_path, ...
                cur_scenario_selection, param_table);
            save(fullfile(cur_scenario_mat_save_path, [cur_scenario_selection '_GT.mat']), ...
                'impact_section', 'pre_crash_true', 'impact_sample_all', ...
                'safe_crash_with_AEB', 'safe_on', 'safe_off', ...
                'crash_on', 'crash_off', 'driving_time', 'driving_distance', 'info', 'impact_speed');
            toc;
        elseif toggle_genCollisionGT == 2 % VRU
            tic;
            [impact_section, pre_crash_true, impact_sample_all, safe_crash_with_AEB, ...
                safe_on, safe_off, crash_on, crash_off, driving_time, driving_distance, ...
                info, impact_speed] = genCollisionGTVRU(mat_path, carmaker_project_path, ...
                cur_scenario_selection, param_table);
            save(fullfile(cur_scenario_erg_save_path, [cur_scenario_selection '_GT.mat']), ...
                'impact_section', 'pre_crash_true', 'impact_sample_all', ...
                'safe_crash_with_AEB', 'safe_on', 'safe_off', ...
                'crash_on', 'crash_off', 'driving_time', 'driving_distance', 'info', 'impact_speed');
            toc;
        end

        % CA GT
        if toggle_genCAGT == 1
            tic;
            Fallback_GT_num = genAESGT(cur_scenario_selection, 1, scenario_generation_path, ...
                carmaker_project_path, mat_path, param_table);
            toc;
        end

        % Movie Export
        if toggle_movie_export == 1
            tic;
            disp('Movie Export Start');
            % Load and process movie generation here if necessary
            toc;
        end
    end
end
