clear; clc;
close all

path_code = pwd;
path_dirErg = '\\192.168.75.251\Shares\2023 Autumn Data\Data\Erg\LK_LF_LF_ST_6503ea21593e0000ba0001b0';
path_dirMat = [path_code '\Mat'];

mkdir(path_dirMat);

path_projectFoler = 'G:\CM_Projects_JSA\JSA_Project';
run([path_projectFoler '\src_cm4sl\cmenv.m'])

scenarioName = 'LK_LF_LF_ST_6503ea21593e0000ba0001b0';
list_mat_old = struct2table(dir([path_dirMat '\' scenarioName '*.mat'])).name;

DlgH = figure;
uiUpdate_breake = uicontrol('Style', 'PushButton', ...
                    'String', 'Break', ...
                    'Callback', 'delete(gcbf)');
list_completeConversion_erg = {};
while (ishandle(uiUpdate_breake))

    clc
    disp('Wait for new erg files...')

    Cur_dirInfo_ergName = struct2table(dir([path_dirErg '\*.erg']));
    Cur_list_ergName_tmp = Cur_dirInfo_ergName.name;
    Cur_list_ergName_tmp_split = cellfun(@(v) strsplit(erase(v,'.erg'),' ') ,Cur_list_ergName_tmp ,'UniformOutput' ,false);
    Cur_dirInfo_ergName.numOf_var = cellfun(@(v) str2num(v{2}) ,Cur_list_ergName_tmp_split);
    Cur_dirInfo_ergName_ascend = sortrows(Cur_dirInfo_ergName,"numOf_var","ascend");
    Cur_dirInfo_ergName_descend = sortrows(Cur_dirInfo_ergName,"numOf_var","descend");
    
    Cur_list_ergName_all = Cur_dirInfo_ergName_ascend.name;

    Cur_list_ergName_needTo_conversion_cand = Cur_list_ergName_all(cell2mat(cellfun(@(v) isempty(find(strcmp(v,list_completeConversion_erg))) ,Cur_list_ergName_all ,'UniformOutput' ,false)));

    tic
    Cur_nameOf_erg_split = cellfun(@(v) strsplit(erase(v,'.erg')) ,Cur_list_ergName_needTo_conversion_cand ,'UniformOutput' ,false);
    Cur_numOf_mat = cellfun(@(v) str2num(v{2}) + 1 ,Cur_nameOf_erg_split);
    Cur_matName_needTo_beCreated_cand = arrayfun(@(v) [scenarioName '_data_' num2str(v) '.mat'] ,Cur_numOf_mat ,'UniformOutput' ,false);
    Cur_idx_needTobeCreated = find(cell2mat(cellfun(@(v) ~contains(v,list_mat_old) ,Cur_matName_needTo_beCreated_cand ,'UniformOutput' ,false)));
    toc

    Cur_list_ergName_needTo_conversion = Cur_list_ergName_needTo_conversion_cand(Cur_idx_needTobeCreated);
    Cur_list_ergName_needTo_beCreated = Cur_matName_needTo_beCreated_cand(Cur_idx_needTobeCreated);

    disp(['Convert ' num2str(length(Cur_list_ergName_needTo_conversion)) ' new erg files'])
    for idx_Cur_list_ergName_needTo_conversion = 1 : length(Cur_list_ergName_needTo_conversion)

        cCur_ergName_needTo_conversion = Cur_list_ergName_needTo_conversion{idx_Cur_list_ergName_needTo_conversion};
        cCur_matName_needTo_beCreated = Cur_list_ergName_needTo_beCreated{idx_Cur_list_ergName_needTo_conversion};

        data = cmread([path_dirErg '\' cCur_ergName_needTo_conversion]);        
        save([path_dirMat '\' cCur_matName_needTo_beCreated],'data')        

        disp(['Converting ' cCur_ergName_needTo_conversion ' to ' cCur_matName_needTo_beCreated ' ...'])
    end

    list_completeConversion_erg = [list_completeConversion_erg ; Cur_list_ergName_needTo_conversion];

    Cur_uiUpdate_numOf_conversion = uicontrol('Style','text',...
                    'String',['Complete ' num2str(height(list_completeConversion_erg)) ' erg files.'],...
                    'Position',[80,5,200,30]);
    Cur_uiUpdate_listOf_conversion = uicontrol('Style','listbox',...
                    'String',list_completeConversion_erg,...
                    'Position',[115,82,200,335]);
   pause(0.5);
end