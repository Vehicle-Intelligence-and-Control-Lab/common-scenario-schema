function movieExport(cur_scenario_selection,mat_path,erg_path,simoutput_path,pre_crash_true)
%% Log
% [ Date: 211224 ]
% Line #: Line35
% Error: movie export시 Ego차량에 너무 Zoom In되어 영상데이터가 보기 힘듦
% Solution: 
% CM-IPG Movie-Camera-Settings에서 Distance를 조정한 'Bird's Eye View (mod)'를 새로 생성하고, Line 36에 view_select를 'Bird's Eye View (mod)'로 수정함
% 특이사항: LK_CCSL_ST에 대해선 movieExport()업데이트 전의 영상이 뽑혔기때문에 다시 뽑을 필요있음

%% Movie Export%%
% cur_scenario_selection
% mat_path
% erg_path
% simoutput_path
% pre_crash_true

dir_save_mat = [ mat_path '\' cur_scenario_selection];                           % mat 경로
dir_save_erg = [ erg_path '\' cur_scenario_selection];                           % erg 경로
dir_movie_erg= [ simoutput_path '\' cur_scenario_selection];                     % project의 movie 폴더

cd(dir_save_mat)
load([ cur_scenario_selection '_GT.mat']);

length_GT=length(pre_crash_true);


first_safe_scenario=find(pre_crash_true(:,1)==0,1);
first_safe_scenario(isempty(first_safe_scenario))=0;
first_crash_scenario=find(pre_crash_true(:,1)~=0,1);
first_crash_scenario(isempty(first_crash_scenario))=0;

export_variation_num=[first_safe_scenario-1,first_crash_scenario-1];

window_Size=[640 480];
maxTime='1200000'; % 120s
view_select="Bird's Eye View (mod)";


disp([cur_scenario_selection ' 시나리오 중 Safe scenario는 ' num2str(export_variation_num(1,1))...
    ', Crash scenario는 ' num2str(export_variation_num(1,2)) ' 입니다.']);

mkdir(dir_movie_erg)

cd(dir_save_erg);

if export_variation_num(1) >= 0
    copyfile(['Variation ' num2str(export_variation_num(1,1)) '.erg.info'],dir_movie_erg)
    copyfile(['Variation ' num2str(export_variation_num(1,1)) '.erg'],dir_movie_erg)
end

if export_variation_num(2) >= 0
    copyfile(['Variation ' num2str(export_variation_num(1,2)) '.erg.info'],dir_movie_erg)
    copyfile(['Variation ' num2str(export_variation_num(1,2)) '.erg'],dir_movie_erg)
end

cd(dir_movie_erg)



dir_movie_erg_4cm = strrep(dir_movie_erg,'\','/');
dir_Save_mat_4cm  = strrep(dir_save_mat,'\','/');

cmguicmd('Movie start');

for j = 1:2
    
    if j==1 && export_variation_num(1) >= 0
        
        k=first_safe_scenario-1;
        mymp4name=['Safe_Scenario_Movie_Variation_' num2str(k) '.mp4'];
        formatSpec = 'Variation %d.erg';
        A1 = k;
        myfilename = sprintf(formatSpec,A1);
        
        erg_file_root = [dir_movie_erg_4cm '/' myfilename];
        
        load_command=['Movie loadsimdata ', '"' erg_file_root '"'];
        
        cmguicmd(load_command);
        
        
        view_command=char(strcat('Movie camera select '," ",'"',  view_select,'"'));
        cmguicmd(view_command);
        
        export_command=['Movie export window ' , '"' dir_Save_mat_4cm '/' mymp4name '"' ' 0 ' ,'-width ' ,num2str(window_Size(1,1)) ,' -height ' ,num2str(window_Size(1,2)) ,' -start 0 -end ',maxTime, ' -format mpeg4 -quality 1'];
        cmguicmd(export_command);
        pause(5);
        
    elseif j==2 && export_variation_num(2) >= 0
        
        k=first_crash_scenario-1;
        mymp4name=['Crash_Scenario_Movie_Variation_' num2str(k) '.mp4'];
        formatSpec = 'Variation %d.erg';
        A1 = k;
        myfilename = sprintf(formatSpec,A1);
        
        erg_file_root = [dir_movie_erg_4cm '/' myfilename];
        
        load_command=['Movie loadsimdata ', '"' erg_file_root '"'];
        
        cmguicmd(load_command);
        
        
        view_command=char(strcat('Movie camera select '," ",'"',  view_select,'"'));
        cmguicmd(view_command);
        
        export_command=['Movie export window ' , '"' dir_Save_mat_4cm '/' mymp4name '"' ' 0 ' ,'-width ' ,num2str(window_Size(1,1)) ,' -height ' ,num2str(window_Size(1,2)) ,' -start 0 -end ',maxTime, ' -format mpeg4 -quality 1'];
        cmguicmd(export_command);
        pause(5);
    end
    
end
end