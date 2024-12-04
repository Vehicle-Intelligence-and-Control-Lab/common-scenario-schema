% function erg2mat_v0_1(path_dirErg,path_dirMat,path_dir_parameterSpace,scenarioName,list_completeConversion_erg,list_completeConversion_mat)
function erg2mat_v0_1(path_dirErg,path_dirMat,path_dir_parameterSpace,scenarioName,list_completeConversion_mat)
mkdir(path_dirMat);

%% Copy parameter space to directory of mat file
copyfile([path_dir_parameterSpace '\' scenarioName '_Param_space.csv'],[path_dirMat '\' scenarioName '_Param_space.csv'])

%% From parameter space extract all ergs' name who need to convert to mat files
param_table = readtable([path_dirMat '\' scenarioName '_Param_space.csv']);
list_ergName_all = cellstr(arrayfun(@(v) ['Variation ' num2str(v) '.erg'] ,param_table.Variation ,'UniformOutput' ,false));

%% Extract list of erg names
% 1. Is there the erg name in parameter space?
% 2. Is there the erg name in erg directory?
% 3. Isn't there the mat file who was converted by the erg?
dirInfo_ergName = struct2table(dir([path_dirErg '\*.erg']));
list_ergNameIn_dir = cellstr(dirInfo_ergName.name);

list_ergName_interest1 = list_ergNameIn_dir;
list_ergName_union = [list_ergName_interest1 ; list_ergName_all];
list_iscomplementOr_intersection = cellfun(@(v) sum(strcmp(v,list_ergName_union)) ,list_ergName_interest1);

% dirInfo_ergName_needToConvert_cand1 = dirInfo_ergName(list_iscomplementOr_intersection == 2,:);
dirInfo_ergName_needToConvert_cand1 = dirInfo_ergName(:,:);
list_ergName_needToConvert_cand1 = cellstr(dirInfo_ergName_needToConvert_cand1.name);
list_ergName_needToConvert_cand1_split = cellfun(@(v) strsplit(erase(v,'.erg'),' ') ,list_ergName_needToConvert_cand1 ,'UniformOutput' ,false);
dirInfo_ergName_needToConvert_cand1.numOf_var = cellfun(@(v) str2num(v{2}) ,list_ergName_needToConvert_cand1_split);

numOf_var = dirInfo_ergName_needToConvert_cand1.numOf_var;
numOf_mat = numOf_var + 1;
matName_needTo_beCreated_cand = arrayfun(@(v) [scenarioName '_data_' num2str(v) '.mat'] ,numOf_mat ,'UniformOutput' ,false);

dirInfo_ergName_needToConvert_cand1.matName_toConvert = matName_needTo_beCreated_cand;

matName_toConvert_interest = cellstr(dirInfo_ergName_needToConvert_cand1.matName_toConvert);
matName_toConvert_union = [list_completeConversion_mat ; matName_toConvert_interest];
list_iscomplementOr_intersection = cellfun(@(v) sum(strcmp(v,matName_toConvert_union)) ,matName_toConvert_interest);

dirInfo_ergName_needToConvert = dirInfo_ergName_needToConvert_cand1(list_iscomplementOr_intersection == 1,:);

% %% Except for the erg files already converted
% dirInfo_ergName = struct2table(dir([path_dirErg '\*.erg']));
% list_ergName_interest = cellstr(dirInfo_ergName.name);
% list_ergName_union = [list_ergName_interest ; list_completeConversion_erg];
% list_iscomplementOr_intersection = cellfun(@(v) sum(strcmp(v,list_ergName_union)) ,list_ergName_interest);
% dirInfo_ergName = dirInfo_ergName(list_iscomplementOr_intersection == 1,:);
%
% %% Except for the mat files already converted
% list_ergName_select2_tmp = cellstr(dirInfo_ergName.name);
% list_ergName_select2_tmp_split = cellfun(@(v) strsplit(erase(v,'.erg'),' ') ,list_ergName_select2_tmp ,'UniformOutput' ,false);
% dirInfo_ergName.numOf_var = cellfun(@(v) str2num(v{2}) ,list_ergName_select2_tmp_split);
%
% numOf_var = dirInfo_ergName.numOf_var;
% numOf_mat = numOf_var + 1;
% matName_needTo_beCreated_cand = arrayfun(@(v) [scenarioName '_data_' num2str(v) '.mat'] ,numOf_mat ,'UniformOutput' ,false);
% dirInfo_ergName.matName_toConvert = matName_needTo_beCreated_cand;
%
% matName_toConvert_interest = cellstr(dirInfo_ergName.matName_toConvert);
% matName_toConvert_union = [list_completeConversion_mat ; matName_toConvert_interest];
% list_iscomplementOr_intersection = cellfun(@(v) sum(strcmp(v,matName_toConvert_union)) ,matName_toConvert_interest);
%
% dirInfo_ergName = dirInfo_ergName(list_iscomplementOr_intersection == 1,:);

%% Sort list of erg files and mat files by ascend
dirInfo_ergName_sort = sortrows(dirInfo_ergName_needToConvert,"numOf_var","ascend");

list_ergName_needTo_conversion = cellstr(dirInfo_ergName_sort.name);
list_matName_needTo_beCreated = cellstr(dirInfo_ergName_sort.matName_toConvert);

if isempty(dirInfo_ergName_sort.name)
    disp('There is no erg files to convert')
else
    disp(['Convert ' num2str(length(list_ergName_needTo_conversion)) ' new erg files'])
    for idx_list_ergName_needTo_conversion = 1 : length(list_ergName_needTo_conversion)

        Cur_ergName_needTo_conversion = list_ergName_needTo_conversion{idx_list_ergName_needTo_conversion};
        Cur_matName_needTo_beCreated = list_matName_needTo_beCreated{idx_list_ergName_needTo_conversion};

        data = cmread([path_dirErg '\' Cur_ergName_needTo_conversion]);
        save([path_dirMat '\' Cur_matName_needTo_beCreated],'data')

        disp(['Converting ' Cur_ergName_needTo_conversion ' to ' Cur_matName_needTo_beCreated ' ...'])
    end
end