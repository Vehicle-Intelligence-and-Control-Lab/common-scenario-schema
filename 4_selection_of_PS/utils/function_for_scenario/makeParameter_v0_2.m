function param_table = makeParameter_v0_2...
    (cur_scenario_selection,save_path,toggle_default_parameter,toggle_nonSampling,info_testrunFile_cell,info_vehicleFile_cell)

% Make Parameter
% Input
% cur_scenario_selection    : Selected scenario
% save_path                 : Save path for paramteter space csv file
% toggle_default_parameter  : 0 - Manual input of parameter
%                             1 - Default input of parameter

% Output
% param_table               : Parameter variation table



%% Log
% [ Date: 211224 ]
% Line #: line103
% Error: LK_CGSR2L_ST시나리오에 대한 'definput'정의가 되지 못하는 error발생
% Solution: 조건문에 LK_CGSR2L_ST 시나리오를 추가, definput이 비어있다면, param_table를 빈행렬로 출력

% [ Date: 211227 ]
% Line #: line112
% Error: LT_CGSR2L_IN시나리오에 대한 'definput'정의가 되지 못하는 error발생
% Solution: 조건문에 LT_CGSR2L_IN 시나리오를 추가

% [ Date: 211228 ]
% 차대차 시나리오 추가


%% Parameter Declaration

% % Scenario description figure

% fig  = figure;
% movegui(fig,[300 600])
% [X1,map1]=imread([ OpenSCENARIO_Path '\' cur_scenario_selection '.JPG']);
% imshow(X1,map1)
% title(['Logical Scenario : ' replace(cur_scenario_selection,'_','-')],'FontSize',15)

%% Make parameter space table mode
if toggle_nonSampling
    toggle_default_parameter = 0;
end

%% Input parameter GUI
% Pedestrian
if strcmp(cur_scenario_selection,'LK_PCSL_ST') % 1
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]

elseif strcmp(cur_scenario_selection,'LK_PCSR_ST') % 2
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_PSTP_ST') % 3
    
    dims = [1 100];
    parameter_declaration = {'v_ego','offset_ego','offset_target'};
    definput = {'10,60,3','-0.9,0.9,3','10,90,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_PWAL_ST') % 4
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','offset_target'};
    definput = {'10,60,3','5,8,3','-0.9,0.9,3','0.3,1.5,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_PWAR_ST') % 5
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','offset_target'};
    definput = {'10,60,3','5,8,3','-0.9,0.9,3','-0.3,-1.5,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_PCSL_STP_ST') % 6
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_PCSR_STP_ST') % 7
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_POCL_ST') % 8
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','offset_target'};
    definput = {'10,60,3','5,8,3','-0.9,0.9,3','0.3,1.5,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_POCR_ST') % 9
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','offset_target'};
    definput = {'10,60,3','5,8,3','-0.9,0.9,3','-0.3,-1.5,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_PCSL_IN') % 10
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_PCSR_IN') % 11
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_POC_IN') % 12
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_PCSL_IN') % 13
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_PCSR_IN') % 14
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','5,8,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
    
    % Cyclist
elseif strcmp(cur_scenario_selection,'LK_CCSL_ST') % 1
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_CCSR_ST') % 2
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'LK_CCIR_ST') % 3
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','duration','dist_trigger'};
    definput = {'10,60,3','13,17,3','3,3,3','30,70,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_CGS_ST') % 4
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','offset_target'};
    definput = {'10,60,3','13,17,3','-0.9,0.9,3','-1.5,1.5,3'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'LK_CSTP_ST') % 5
    
    dims = [1 100];
    parameter_declaration = {'v_ego','offset_ego','offset_target'};
    definput = {'10,60,3','-0.9,0.9,3','-1.5,1.5,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_COCL_ST') % 6
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','duration','dist_trigger'};
    definput = {'10,60,3','13,17,3','2,3,3','50,100,3'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_CGSL2R_IN') % 7
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_CGSR2L_IN') % 8
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_CCSL_IN') % 9
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_CCSR_IN') % 10
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'LT_CGSR2L_IN') % 11
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_COC_IN') % 12
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_CCSR_IN') % 13
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_CCSL_IN') % 14
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'RT_CGSL2R_IN') % 15
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_CGSR2L_IN') % 16
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','13,17,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'RT_CSD_IN') % 17
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,3','13,17,3','-0.9,0.9,3','10,90,3'}; % [min, max, number of sampling points]
    
    % E-Scooter
elseif strcmp(cur_scenario_selection,'LK_ECSL_ST') % 1
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_ECSL_STP_ST') % 2
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_EGSL2R_IN') % 3
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_EGSR2L_IN') % 4
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_ECSL_IN') % 5
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_EOC_IN') % 6
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_EGSR2L_IN') % 7
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_ECSR_IN') % 8
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_ECSL_IN') % 9
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_EGSL2R_IN') % 10
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_EGSR2L_IN') % 11
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_ego','dist_trigger'};
    definput = {'10,60,10','20,30,10','-0.9,0.9,10','10,90,10'}; % [min, max, number of sampling points]
    
    
    % Car
elseif contains(cur_scenario_selection,'LK_LF_') % 1-2
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','a_target','R_dec'};
    definput = {'30,110,5','30, 110,5','-1.8, 1.8,5','-8, -2,5','10, 50,5'}; % [min, max, number of sampling points]
    
    % select parameter
    % mode1(offset_target)
    % extract ego and target width
    info_sizeOfBBox_ego = strip(info_vehicleFile_cell{...
        cell2mat(cellfun(@(v) contains(v, 'Vehicle.OuterSkin = '), info_vehicleFile_cell, 'UniformOutput', false))...
        });
    sizeOfBBox_ego = str2num(strip(info_sizeOfBBox_ego(regexp(info_sizeOfBBox_ego,'Vehicle.OuterSkin = ','end'):end)));
    widthOfBBox_ego = abs(sizeOfBBox_ego(5) - sizeOfBBox_ego(2));
    
    info_sizeOfVehicle_target = strip(info_testrunFile_cell{...
        cell2mat(cellfun(@(v) contains(v, 'Traffic.0.Basics.Dimension = '), info_testrunFile_cell, 'UniformOutput', false))...
        });
    sizeOfVehicle_target = str2num(strip(info_sizeOfVehicle_target(regexp(info_sizeOfVehicle_target,'Traffic.0.Basics.Dimension = ','end'):end)));
    widthOfVehicle_target = sizeOfVehicle_target(2);
    
    % make values of 'offset_target'
    non_overlap = widthOfVehicle_target/2 + 3*widthOfBBox_ego/4;
    overlap50 = widthOfVehicle_target/2;
    overlap75 = widthOfVehicle_target/2 - widthOfBBox_ego/4;
    overlap100 = 0;
    overlapNeg50 = -overlap50;
    overlapNeg75 = -overlap75;
    non_overlapNeg = -non_overlap;
    
    definput{(cellfun(@(v) strcmp(v,'offset_target'),parameter_declaration))} =...
        ['[' strjoin({num2str(non_overlapNeg) num2str(overlapNeg50) num2str(overlapNeg75) num2str(overlap100) num2str(overlap75) num2str(overlap50) num2str(non_overlap)},',') ']'];
    
% elseif strcmp(cur_scenario_selection,'LK_LF_SH') % 2
%     
%     dims = [1 100];
%     parameter_declaration = {'v_ego','v_target','offset_target','a_target','R_dec'};
%     definput = {'30,110,5','30, 110,5','-1.8, 1.8,5','-8, -2,5','10, 50,5'}; % [min, max, number of sampling points]

elseif contains(cur_scenario_selection,'LK_CIL_') % 3-5
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','t_cut_in','a_target','R_cut_in'};
    definput = {'30,110,5','30, 110,5','1, 5,5','-8, 0,5','10, 50,5'}; % [min, max, number of sampling points]

elseif contains(cur_scenario_selection,'LK_CIR_') % 6-8
    
    if contains(cur_scenario_selection,'_MER')
        dims = [1 100];
        parameter_declaration = {'v_ego','v_target','R_cut_in'};
        definput = {'30,110,5','30, 110,5','50,90,5'}; % [min, max, number of sampling points]
    else
        dims = [1 100];
        parameter_declaration = {'v_ego','v_target','t_cut_in','a_target','R_cut_in'};
        definput = {'30,110,5','30, 110,5','1, 5,5','-8, 0,5','10, 50,5'}; % [min, max, number of sampling points]
    end
%     
% elseif strcmp(cur_scenario_selection,'LK_CIR_MER') % 8
%     
%     dims = [1 100];
%     parameter_declaration = {'v_ego','v_target','R_cut_in'};
%     definput = {'30,110,5','30, 110,5','50,90,5'}; % [min, max, number of sampling points]
    
elseif contains(cur_scenario_selection,'LK_COL_STP_') % 9
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_start','duration','dist_trigger'};
    definput = {'30,110,5','30, 110,5','15, 25,5','1, 3,5','20, 50,5'}; % [min, max, number of sampling points]

elseif contains(cur_scenario_selection,'LK_COR_STP_') % 11-12
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_start','duration','dist_trigger'};
    definput = {'30,110,5','30, 110,5','15, 25,5','1, 3,5','20, 50,5'}; % [min, max, number of sampling points]

elseif contains(cur_scenario_selection,'LK_STP_') % 13-14
    
    dims = [1 100];
    parameter_declaration = {'v_ego','offset_ego','offset_target'};
    definput = {'30,110,5','-0.9, 0.9,5','-0.9, 0.9,5'}; % [min, max, number of sampling points]
    
    % select parameter
    % mode1(offset_target)
    % extract ego and target width
    info_sizeOfBBox_ego = strip(info_vehicleFile_cell{...
        cell2mat(cellfun(@(v) contains(v, 'Vehicle.OuterSkin = '), info_vehicleFile_cell, 'UniformOutput', false))...
        });
    sizeOfBBox_ego = str2num(strip(info_sizeOfBBox_ego(regexp(info_sizeOfBBox_ego,'Vehicle.OuterSkin = ','end'):end)));
    widthOfBBox_ego = abs(sizeOfBBox_ego(5) - sizeOfBBox_ego(2));
    
    info_sizeOfVehicle_target = strip(info_testrunFile_cell{...
        cell2mat(cellfun(@(v) contains(v, 'Traffic.0.Basics.Dimension = '), info_testrunFile_cell, 'UniformOutput', false))...
        });
    sizeOfVehicle_target = str2num(strip(info_sizeOfVehicle_target(regexp(info_sizeOfVehicle_target,'Traffic.0.Basics.Dimension = ','end'):end)));
    widthOfVehicle_target = sizeOfVehicle_target(2);
    
    % make values of 'offset_target'
    non_overlap = widthOfVehicle_target/2 + 3*widthOfBBox_ego/4;
    overlap50 = widthOfVehicle_target/2;
    overlap75 = widthOfVehicle_target/2 - widthOfBBox_ego/4;
    overlap100 = 0;
    overlapNeg50 = -overlap50;
    overlapNeg75 = -overlap75;
    non_overlapNeg = -non_overlap;
    
    definput{(cellfun(@(v) strcmp(v,'offset_target'),parameter_declaration))} =...
        ['[' strjoin({num2str(non_overlapNeg) num2str(overlapNeg50) num2str(overlapNeg75) num2str(overlap100) num2str(overlap75) num2str(overlap50) num2str(non_overlap)},',') ']'];    

elseif contains(cur_scenario_selection,'LK_OVE_') % 15-16
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_trigger'};
    definput = {'30,110,5','30, 110,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_BWD_ST') % 17
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_trigger'};
    definput = {'30,110,5','-5, -1,5','10, 50,5'}; % [min, max, number of sampling points]
    
    
elseif strcmp(cur_scenario_selection,'LCL_LF_ST') % 18
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','duration','dist_trigger'};
    definput = {'30,110,5','30, 110,5','1, 3,5','5, 15,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LCR_LF_ST') % 19
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','duration','dist_trigger'};
    definput = {'30,110,5','30, 110,5','1, 3,5','5, 15,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'UT_LF_ST') % 20
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_trigger'};
    definput = {'5,25,5','30, 110,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'UT_OVE_ST') % 21
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','dist_trigger'};
    definput = {'5,25,5','30, 110,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_LFL2R_IN') % 22
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_LFR2L_IN') % 23
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_RTR2SD_IN') % 24
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LK_LTOD2R_IN') % 25
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_LFL2R_IN') % 26
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_LFR2L_IN') % 27
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'LT_OVE_IN') % 28
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
elseif strcmp(cur_scenario_selection,'RT_LFL2R_IN') % 29
    
    dims = [1 100];
    parameter_declaration = {'v_ego','v_target','offset_target','dist_trigger'};
    definput = {'30,60,5','30, 60,5','-0.9, 0.9,5','10, 50,5'}; % [min, max, number of sampling points]
    
else
    
    parameter_declaration = [];
    definput = [];
    
end











if toggle_default_parameter
    parameter_range_input = definput';
    close all

elseif toggle_nonSampling
    dlgtitle = 'parameter(min,max,sampling points) or parameter(value1,value2,...)';
    parameter_range_input = inputdlg(parameter_declaration,dlgtitle,dims,definput);
    close all

else
    dlgtitle = 'parameter(min,max,sampling points)';
    parameter_range_input = inputdlg(parameter_declaration,dlgtitle,dims,definput);
    close all
end


%% Make Parameter Table
clearvars Parameter_Variable_Array*
clearvars P_*

parameter_variables_length = length(parameter_declaration);

if ~isempty(definput)
    
    for parameter_index = 1 : parameter_variables_length
                
        parameter_range = parameter_range_input(parameter_index,1);
        
        if contains(char(parameter_range),']')
            eval([ char(parameter_declaration(parameter_index)) '=' char(parameter_range) ';'])
        else
            eval([ char(parameter_declaration(parameter_index)) '=linspace(' char(parameter_range) ');'])
        end
        
        eval([ 'parameter_variable_array_' num2str(parameter_index) ' = ' char(parameter_declaration(parameter_index))  ';'])
        
    end
    
    tmp_param_text     = [];
    tmp_variation_text = [];
    for tmp_i = 1 : parameter_variables_length
        if tmp_i==1
            tmp_param_text     = [ 'parameter_variable_array_' num2str(tmp_i) '(:) '];
            tmp_variation_text = [ 'P_' num2str(tmp_i) ];
        else
            tmp_param_text     = [ tmp_param_text ', parameter_variable_array_' num2str(tmp_i) '(:) '];
            tmp_variation_text = [ tmp_variation_text ',P_' num2str(tmp_i) ];
        end
    end
    
    eval(['param_array = allcomb(' tmp_param_text ');'])
    [length_param,~]=size(param_array);
    
    variation_array = 0:length_param-1;
    param_table = table(variation_array');
    param_table.Properties.VariableNames = {'Variation'};
    
    for tmp_i = 1 : parameter_variables_length
        param_table(:,tmp_i+1) = table(param_array(:,tmp_i));
        param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
    end
    
    for variable_index = 1 : parameter_variables_length
        Variable_Name = char(param_table.Properties.VariableNames(variable_index+1));
        eval(['index.' Variable_Name ' = ' num2str(variable_index) ';'])
    end
    
    %% Critical Scenario Classification
    if strcmp(cur_scenario_selection,'LK_PCSL_ST') || strcmp(cur_scenario_selection,'LK_PCSR_ST')...
            || strcmp(cur_scenario_selection,'LK_PCSL_STP_ST') || strcmp(cur_scenario_selection,'LK_PCSR_STP_ST')...
            || strcmp(cur_scenario_selection,'LK_CCSL_ST') || strcmp(cur_scenario_selection,'LK_CCSR_ST')...
            || strcmp(cur_scenario_selection,'LT_PCSL_IN') || strcmp(cur_scenario_selection,'LT_PCSR_IN')...
            || strcmp(cur_scenario_selection,'LT_POC_IN') || strcmp(cur_scenario_selection,'RT_PCSL_IN')...
            || strcmp(cur_scenario_selection,'RT_PCSR_IN') || strcmp(cur_scenario_selection,'LK_CCSL_ST')...
            || strcmp(cur_scenario_selection,'LK_CCSR_ST') || strcmp(cur_scenario_selection,'LK_CGSL2R_IN')...
            || strcmp(cur_scenario_selection,'LK_CGSR2L_IN') || strcmp(cur_scenario_selection,'LT_CCSL_IN')...
            || strcmp(cur_scenario_selection,'LT_CCSR_IN') || strcmp(cur_scenario_selection,'LT_CGSR2L_IN')...
            || strcmp(cur_scenario_selection,'LT_COC_IN') || strcmp(cur_scenario_selection,'RT_CCSL_IN')...
            || strcmp(cur_scenario_selection,'RT_CCSR_IN') || strcmp(cur_scenario_selection,'RT_CGSL2R_IN') || strcmp(cur_scenario_selection,'RT_CGSR2L_IN')...
            || strcmp(cur_scenario_selection,'LK_ECSL_ST') || strcmp(cur_scenario_selection,'LK_ECSL_STP_ST')...
            || strcmp(cur_scenario_selection,'LK_EGSL2R_IN') || strcmp(cur_scenario_selection,'LK_EGSR2L_IN')...
            || strcmp(cur_scenario_selection,'LT_ECSL_IN') || strcmp(cur_scenario_selection,'LT_EGSR2L_IN')...
            || strcmp(cur_scenario_selection,'LT_EOC_IN') || strcmp(cur_scenario_selection,'RT_ECSR_IN')...
            || strcmp(cur_scenario_selection,'RT_ECSR_IN') || strcmp(cur_scenario_selection,'RT_EGSL2R_IN')...
            || strcmp(cur_scenario_selection,'RT_EGSR2L_IN')
        
        
        % Parameter for search
        if strcmp(cur_scenario_selection,'LK_PCSL_ST') || strcmp(cur_scenario_selection,'LK_PCSR_ST')...
                || strcmp(cur_scenario_selection,'LK_PCSL_STP_ST') || strcmp(cur_scenario_selection,'LK_PCSR_STP_ST')...
                || strcmp(cur_scenario_selection,'LK_CCSL_ST') || strcmp(cur_scenario_selection,'LK_CCSR_ST')...
                || strcmp(cur_scenario_selection,'LT_PCSL_IN') || strcmp(cur_scenario_selection,'LT_PCSR_IN')...
                || strcmp(cur_scenario_selection,'RT_PCSL_IN') || strcmp(cur_scenario_selection,'RT_PCSR_IN')...
                || strcmp(cur_scenario_selection,'LK_CCSL_ST') || strcmp(cur_scenario_selection,'LK_CCSR_ST')...
                || strcmp(cur_scenario_selection,'LT_CCSL_IN') || strcmp(cur_scenario_selection,'LT_CCSR_IN')...
                || strcmp(cur_scenario_selection,'RT_CCSL_IN') || strcmp(cur_scenario_selection,'RT_CCSR_IN')...
                || strcmp(cur_scenario_selection,'LK_ECSL_ST') || strcmp(cur_scenario_selection,'LK_ECSL_STP_ST')...
                || strcmp(cur_scenario_selection,'LT_ECSL_IN') || strcmp(cur_scenario_selection,'RT_ECSR_IN')...
                || strcmp(cur_scenario_selection,'RT_ECSR_IN')
            
            LENGTH_EGO        = 4.236;
            WIDTH_EGO         = 1.6;
            INIT_LAT_REL_DIST   = 6 - WIDTH_EGO/2;
            
        elseif strcmp(cur_scenario_selection,'LT_POC_IN')
            
            LENGTH_EGO        = 4.236;
            WIDTH_EGO         = 1.6;
            INIT_LAT_REL_DIST   = 23 - WIDTH_EGO/2;
            
        elseif strcmp(cur_scenario_selection,'LK_CGSL2R_IN') || strcmp(cur_scenario_selection,'LK_EGSL2R_IN')
            
            
            LENGTH_EGO        = 4.236;
            WIDTH_EGO         = 1.6;
            INIT_LAT_REL_DIST   = 30 - WIDTH_EGO/2;
            
        elseif strcmp(cur_scenario_selection,'LK_CGSR2L_IN') || strcmp(cur_scenario_selection,'LT_CGSR2L_IN')...
                || strcmp(cur_scenario_selection,'RT_CGSL2R_IN') || strcmp(cur_scenario_selection,'RT_CGSR2L_IN')...
                || strcmp(cur_scenario_selection,'LK_EGSR2L_IN') || strcmp(cur_scenario_selection,'LT_EGSR2L_IN')...
                || strcmp(cur_scenario_selection,'RT_EGSL2R_IN') ||  strcmp(cur_scenario_selection,'RT_EGSR2L_IN')
            
            
            LENGTH_EGO        = 4.236;
            WIDTH_EGO         = 1.6;
            INIT_LAT_REL_DIST   = 20 - WIDTH_EGO/2;
            
        elseif strcmp(cur_scenario_selection,'LT_COC_IN') || strcmp(cur_scenario_selection,'LT_EOC_IN')
            
            LENGTH_EGO        = 4.236;
            WIDTH_EGO         = 1.6;
            INIT_LAT_REL_DIST   = 33 - WIDTH_EGO/2;
            
        end
        
        index.TTC_trigger         = parameter_variables_length+1;
        
        v_ego               = param_table.v_ego/3.6;
        v_target            = param_table.v_target/3.6;
        dist_trigger        = param_table.dist_trigger;
        rel_velocity        = v_ego-v_target;
        TTC_trigger         = dist_trigger ./ rel_velocity;
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.offset_ego)    = param_table.offset_ego;
        total_array(:,index.dist_trigger)  = param_table.dist_trigger;
        total_array(:,index.TTC_trigger)   = TTC_trigger;
        
        
        
        in_lane_time  = INIT_LAT_REL_DIST ./ v_target;
        in_lane_time_long_rel_dist = dist_trigger - v_ego .* in_lane_time;
        
        in_lane_time_TTC = in_lane_time_long_rel_dist ./ v_ego;
        
        % Constraint
        % Longitudinal constraint
        total_array_const_1_index = find(in_lane_time_long_rel_dist > - LENGTH_EGO);
        total_array_const_1 = total_array(total_array_const_1_index,:);
        
        % SVM
        tmp_x = [in_lane_time_TTC(total_array_const_1_index)'; param_table.v_ego(total_array_const_1_index)'; in_lane_time_long_rel_dist(total_array_const_1_index)'];
        w     = [0.8760; -0.0908; 0.3695;];
        b     = -0.1916;
        
        total_array_const_final_index = find(w' * tmp_x + b < 0);
        total_array_const_final = total_array_const_1(total_array_const_final_index,:);
        
        % Save Param_space.csv
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
        
        
    elseif strcmp(cur_scenario_selection,'RT_CSD_IN')
        
        v_ego               = param_table.v_ego/3.6;
        v_target            = param_table.v_target/3.6;
        dist_trigger        = param_table.dist_trigger;
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.offset_ego)    = param_table.offset_ego;
        total_array(:,index.dist_trigger)  = param_table.dist_trigger;
        
        %
        time_target_arrive_IN = 20 ./ v_target;
        time_ego_arrive_IN = (20 + dist_trigger) ./ v_ego;
        
        total_array_const_1_index = find(time_ego_arrive_IN - time_target_arrive_IN > 2 | time_ego_arrive_IN - time_target_arrive_IN > -1);
        total_array_const_final = total_array(total_array_const_1_index,:);
        
        % Save Param_space.csv
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
        
    elseif strcmp(cur_scenario_selection,'LK_LF_ST') || strcmp(cur_scenario_selection,'LK_LF_SH')
        
        index.TTC_Trigger         = parameter_variables_length+1;
        
        ego_velocity        = param_table.v_ego;
        target_velocity     = param_table.v_target;
        R_decelleration     = param_table.R_dec;
        rel_velocity        = (ego_velocity-target_velocity)/3.6;
        TTC_trigger         = R_decelleration ./ rel_velocity;
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.offset_target) = param_table.offset_target;
        total_array(:,index.a_target)      = param_table.a_target;
        total_array(:,index.R_dec)         = param_table.R_dec;
        total_array(:,index.TTC_Trigger)   = TTC_trigger;
        
        
        total_array_const_1 = total_array(ego_velocity > target_velocity,:);
        
        w = [0.277777755761208;2.09363587159429e-17;0.222222213860805];
        b = -0.722222177184927;
        total_array_const_final = total_array_const_1(total_array_const_1(:,index.a_target) < -(w(1).*total_array_const_1(:,index.TTC_Trigger) + w(2).*total_array_const_1(:,index.offset_target)+b)./w(3),:);
        
        
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
        
    elseif strcmp(cur_scenario_selection,'LK_CIL_ST') || strcmp(cur_scenario_selection,'LK_CIL_SH')...
            || strcmp(cur_scenario_selection,'LK_CIL_CU') || strcmp(cur_scenario_selection,'LK_CIR_ST')...
            || strcmp(cur_scenario_selection,'LK_CIR_CU')
        
        index.TTC_Trigger         = parameter_variables_length+1;
        index.t_cut_in_max        = parameter_variables_length+2;
        
        ego_velocity        = param_table.v_ego;
        target_velocity     = param_table.v_target;
        R_cut_in            = param_table.R_cut_in;
        a_target            = param_table.a_target;
        rel_velocity        = (ego_velocity-target_velocity)/3.6;
        TTC_trigger         = R_cut_in ./ rel_velocity;
        t_cut_in_max        = (0.1-target_velocity/3.6)./a_target;
        
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.a_target)      = param_table.a_target;
        total_array(:,index.t_cut_in)      = param_table.t_cut_in;
        total_array(:,index.R_cut_in)      = param_table.R_cut_in;
        total_array(:,index.TTC_Trigger)   = TTC_trigger;
        total_array(:,index.t_cut_in_max)  = t_cut_in_max;
                
        % Longitudinal constraint
        total_array_const_1 = total_array(ego_velocity > target_velocity,:);

        % % Lateral constraint
        % total_array_const_2 = total_array_const_1(total_array_const_1(:,index.t_cut_in_max) >= total_array_const_1(:,index.t_cut_in) | total_array_const_1(:,index.t_cut_in_max) == -inf,:);        
        
        w = [-0.230309847345103;1.07876061091836;-1.37364648016824];
        b = -2.84247877940042;
        
        total_array_const_final = total_array_const_1(total_array_const_1(:,index.TTC_Trigger) > -(w(1).*total_array_const_1(:,index.a_target) + w(2).*total_array_const_1(:,index.t_cut_in)+b)./w(3),:);
        
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
    elseif strcmp(cur_scenario_selection,'LK_COL_STP_ST') || strcmp(cur_scenario_selection,'LK_COL_STP_SH')...
            || strcmp(cur_scenario_selection,'LK_COR_STP_ST') || strcmp(cur_scenario_selection,'LK_COR_STP_CU')
                
        ego_velocity        = param_table.v_ego;
        target_velocity     = param_table.v_target;
        dist_trigger        = param_table.dist_trigger;
        rel_velocity        = (ego_velocity-target_velocity)/3.6;
        
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.dist_start)    = param_table.dist_start;
        total_array(:,index.duration)      = param_table.duration;
        total_array(:,index.dist_trigger)  = param_table.dist_trigger;
        
        % Longitudinal constraint
        total_array_const_1 = total_array(ego_velocity == target_velocity,:);
        
        total_array_const_final = total_array_const_1;
        
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
    elseif strcmp(cur_scenario_selection,'LCL_LF_ST') || strcmp(cur_scenario_selection,'LCR_LF_ST')
        
        ego_velocity        = param_table.v_ego;
        target_velocity     = param_table.v_target;
        rel_velocity        = (ego_velocity-target_velocity)/3.6;
        
        
        total_array(:,index.v_ego)         = param_table.v_ego;
        total_array(:,index.v_target)      = param_table.v_target;
        total_array(:,index.duration)      = param_table.duration;
        total_array(:,index.dist_trigger)  = param_table.dist_trigger;
        
        % Longitudinal constraint
        total_array_const_1 = total_array(ego_velocity < target_velocity,:);
        
        total_array_const_final = total_array_const_1;
        
        [length_param_array,~]=size(total_array_const_final);
        variation_array = 0:length_param_array-1;
        param_table = table(variation_array');
        param_table.Properties.VariableNames = {'Variation'};
        
        for tmp_i = 1 : parameter_variables_length
            param_table(:,tmp_i+1) = table(total_array_const_final(:,tmp_i));
            param_table.Properties.VariableNames(tmp_i+1) = {char(parameter_declaration(tmp_i))};
        end
        
    end
    
    
    
    
    
    
    writetable(param_table,[save_path '\' cur_scenario_selection '\' cur_scenario_selection '_Param_space.csv'])
    
    
else
    param_table = [];
end

end
