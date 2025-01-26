function erg2mat(cur_scenario_selection,variable_array,erg_path,save_path)
%% ERG 2 MAT %%
%%%%%%%%%%%%%%%%%
% Data_Path
% Variable_array
% cur_scenario_selection

cd(erg_path)
% cd(save_path)
data_num = length(variable_array(:,1));

for data_index  = 1: data_num
    
    format_spec = 'Variation %d.erg';
    variation_number = variable_array(data_index,1);
    filename = sprintf(format_spec,variation_number);
    
    disp('')
    disp([' Exporting Variation ',num2str(variation_number),'...'])
    
    
    data = cmread(filename);
    
    
    mat_file_name = sprintf([cur_scenario_selection '_data_%d.mat'],variable_array(data_index,1)+1);
    
    
    save(mat_file_name,'data')
    
    disp([' Exported Variation ',num2str(variation_number), ' to ',...
        cur_scenario_selection,'_data_',num2str(variable_array(data_index,1)+1),' !'])
    disp('  ')
    
end

disp([cur_scenario_selection,' : Exported ERG2MAT Completely!!']);
disp('  ')

end