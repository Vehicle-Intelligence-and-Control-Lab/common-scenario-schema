function Fallback_GT_num=genAESGT(Cur_Scenario_Selection,Last_Var_Num,Scenario_Generation_Path,CarMaker_Project_Path,Data_Path,Ori_Param_table)

% Fallback GT script
% ver 121120
% ver 032121(new version)
% Traffic position velocity read > FreeMotion control
% Fallback testrun auto generation
% Cur_Scenario_Selection='LK_LF_ST';

Ori_Scenario   = Cur_Scenario_Selection;
Dir_Code       = [ Scenario_Generation_Path '\Scenario function'];

%% Settings_tmp
% path
Cm4sl_Path                  = [CarMaker_Project_Path '\src_cm4sl'];
Simulink_Model              = 'generic';

% load files
load([Data_Path '\' Cur_Scenario_Selection '\' Cur_Scenario_Selection '_GT']);
% load([Data_Path '\' Cur_Scenario_Selection '\' Cur_Scenario_Selection '_data_1']);
Ori_impact_section = impact_section;
addpath([Scenario_Generation_Path '\Scenario function'])

%%
toggle_Test = 0;
% Ori_Scenario =  Cur_Scenario_Selection;

Dir_Original = [ Data_Path '\' Ori_Scenario];

cd(Dir_Original)
% Ori_GT = load([ Ori_Scenario '_GT.mat']);
Ori_Param_table=readtable([ Ori_Scenario '_Param_space.csv']);
Switch_ACC = 0;
Switch_DEC = 0;
Switch_ESL = 0;
Switch_ESR = 0;
Switch_ESS = 0;
Switch_ELCL = 0;
Switch_ELCR = 0;

%% Scenario 별 Fallback Strategy


if contains(Ori_Scenario,'LK_LF_ST')
    Switch_ACC = 0;
    Switch_DEC = 0;
    Switch_ESL = 1;
    Switch_ESR = 1;
    Switch_ESS = 0;
    Switch_ELCL = 1;
    Switch_ELCR = 1;
elseif contains(Ori_Scenario,'LK_CIL_ST')
    Switch_ACC = 0;
    Switch_DEC = 0;
    Switch_ESL = 0;
    Switch_ESR = 1;
    Switch_ESS = 0;
    Switch_ELCL = 0;
    Switch_ELCR = 1;
elseif strcmp(Ori_Scenario,'LK_CIR_ST')
    Switch_ACC = 0;
    Switch_DEC = 0;
    Switch_ESL = 1;
    Switch_ESR = 0;
    Switch_ESS = 0;
    Switch_ELCL = 1;
    Switch_ELCR = 0;
elseif strcmp(Ori_Scenario,'LK_COL_STP_ST')
    Switch_ACC = 0;
    Switch_DEC = 0;
    Switch_ESL = 0;
    Switch_ESR = 0;
    Switch_ESS = 0;
    Switch_ELCL = 1;
    Switch_ELCR = 1;
elseif strcmp(Ori_Scenario,'LK_COR_STP_ST')
    Switch_ACC = 0;
    Switch_DEC = 0;
    Switch_ESL = 0;
    Switch_ESR = 0;
    Switch_ESS = 0;
    Switch_ELCL = 1;
    Switch_ELCR = 1;
end



cd([Data_Path '\' Ori_Scenario])
Annotation_Fallback=[table2array(Ori_Param_table(:,1)) zeros(length(table2array(Ori_Param_table(:,1))),7)];
% save('Annotation_Fallback','Annotation_Fallback');

%% ACC
if Switch_ACC
    disp('ACC simulation is started')
    run([Dir_Code '\Strategy\strategyACC']);
    cd([ Dir_Original '_ACC'])
    
    Cur_Strategy = 'ACC';
    Cur_Strategy_num = 0;
    
    Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
    Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
    
    
    Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
    
    Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
    
    index_collision = find(Cur_GT.impact_section(:,1)~=0);
    Val_num_collision = table2array(Cur_Param_table(index_collision,1));
    Col_num_collision = Val_num_collision-Last_Var_Num;
    
    Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2; ;                                                               % 2 해당 Fallback 전략 실행 중 Collsision
    
    ACC = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                             % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end

%% DEC

if Switch_DEC
    disp('DEC simulation is started')
    run([Dir_Code '\Strategy\strategyDEC' ]);
    cd([ Dir_Original '_DEC'])
    
    Cur_Strategy = 'DEC';
    Cur_Strategy_num = 1;
    
    Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
    Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
    
    
    Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
    
    Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
    
    index_collision = find(Cur_GT.impact_section(:,1)~=0);
    Val_num_collision = table2array(Cur_Param_table(index_collision,1));
    Col_num_collision = Val_num_collision-Last_Var_Num;
    
    Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                               % 2 해당 Fallback 전략 실행 중 Collsision
    
    DEC = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                             % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end

%% ESL

if Switch_ESL
    disp('ESL simulation is started')
    run([Dir_Code '\Strategy\strategyESL' ]);
    cd([ Dir_Original '_ESL'])
    
    Cur_Strategy = 'ESL';
    Cur_Strategy_num = 2;
    
    Cur_Param_table = readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
    Cur_GT          = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
    
    
    Col_num = table2array(Cur_Param_table(:,1)) + 1;
    
    Annotation_Fallback(Col_num+1,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
    
    index_collision = find(Cur_GT.impact_section(:,1)~=0);
    Val_num_collision = table2array(Cur_Param_table(index_collision,1));
    Col_num_collision = Val_num_collision+1;
    
    Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                                % 2 해당 Fallback 전략 실행 중 Collsision
    
    ESL = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                                   % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end

%% ESR

if Switch_ESR
    disp('ESR simulation is started')
    run([Dir_Code '\Strategy\strategyESR' ]);
    cd([ Dir_Original '_ESR'])
    
    Cur_Strategy = 'ESR';
    Cur_Strategy_num = 3;
    
    if ~isempty(Fallback_index)
        Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
        Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
        
        
        Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
        
        Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
        
        index_collision = find(Cur_GT.impact_section(:,1)~=0);
        Val_num_collision = table2array(Cur_Param_table(index_collision,1));
        Col_num_collision = Val_num_collision-Last_Var_Num;
        
        Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                               % 2 해당 Fallback 전략 실행 중 Collsision
    end
    ESR = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                                   % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end
%% ESS

if Switch_ESS
    disp('ESS simulation is started')
    run([Dir_Code '\Strategy\strategyESS' ]);
    cd([ Dir_Original '_ESS'])
    
    Cur_Strategy = 'ESS';
    Cur_Strategy_num = 4;
    if ~isempty(Fallback_index)
        
        Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
        Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
        
        
        Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
        
        Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
        
        index_collision = find(Cur_GT.impact_section(:,1)~=0);
        Val_num_collision = table2array(Cur_Param_table(index_collision,1));
        Col_num_collision = Val_num_collision-Last_Var_Num;
        
        Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                                % 2 해당 Fallback 전략 실행 중 Collsision
    end
    ESS = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                                   % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
    
end
%% ELCL

if Switch_ELCL
    disp('ELCL simulation is started')
    run([Dir_Code '\Strategy\strategyELCL' ]);
    cd([ Dir_Original '_ELCL'])
    
    Cur_Strategy = 'ELCL';
    Cur_Strategy_num = 5;
    if ~isempty(Fallback_index)
        
        Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
        Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
        
        Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
        
        Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
        
        index_collision = find(Cur_GT.impact_section(:,1)~=0);
        Val_num_collision = table2array(Cur_Param_table(index_collision,1));
        Col_num_collision = Val_num_collision-Last_Var_Num;
        
        Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                               % 2 해당 Fallback 전략 실행 중 Collsision
    end
    ELCL = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                                   % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end

%% ELCR
if Switch_ELCR
    disp('ELCR simulation is started')
    run([Dir_Code '\Strategy\strategyELCR' ]);
    cd([ Dir_Original '_ELCR'])
    
    Cur_Strategy = 'ELCR';
    Cur_Strategy_num = 6;
    if ~isempty(Fallback_index)
        
        Cur_Param_table=readtable([ Ori_Scenario '_' Cur_Strategy '_Param_space.csv']);
        Cur_GT = load([ Ori_Scenario '_' Cur_Strategy '_GT.mat']);
        Col_num = table2array(Cur_Param_table(:,1)) - Last_Var_Num;
        
        Annotation_Fallback(Col_num,Cur_Strategy_num+2)=1;                                               % 1 해당 Fallback 전략 실행
        
        index_collision = find(Cur_GT.impact_section(:,1)~=0);
        Val_num_collision = table2array(Cur_Param_table(index_collision,1));
        Col_num_collision = Val_num_collision-Last_Var_Num;
        
        Annotation_Fallback(Col_num_collision,Cur_Strategy_num+2)=2;                                                          % 2 해당 Fallback 전략 실행 중 Collsision
    end
    ELCR = length(find(Annotation_Fallback(:,Cur_Strategy_num+2)==1))                                                                   % 해당 Fallback GT
    
    cd(Dir_Original)
    
    %     save('Annotation_Fallback','Annotation_Fallback');
end

%% Fallback GT num
cd([Data_Path '\' Ori_Scenario])

for i=1:length(Annotation_Fallback(:,1)) % 행 길이
    for k=2:length(Annotation_Fallback(1,:)) % 열 길이
        
        if Annotation_Fallback(i,k)==1
            
            Fallback_GT_num(i,1) = k - 2;
            break;
            
        end
        
        
        if k==length(Annotation_Fallback(1,:)) && sum(Annotation_Fallback(i,2:k))~=0
            Fallback_GT_num(i,1) = 7;  % CM
        else
            Fallback_GT_num(i,1) = 8;  % Original Safe
        end
        
        
        
    end
end



disp(['AES GT Count'])

ESL  = length(find(Fallback_GT_num==2));
ESR  = length(find(Fallback_GT_num==3));
ESS  = length(find(Fallback_GT_num==4));
ELCL = length(find(Fallback_GT_num==5));
ELCR = length(find(Fallback_GT_num==6));
CM   = length(find(Fallback_GT_num==7));
Safe = length(find(Fallback_GT_num==8));

disp(['ESL : ' num2str(ESL)])
disp(['ESR : ' num2str(ESR)])
disp(['ESS : ' num2str(ESS)])
disp(['ELCL : ' num2str(ELCL)])
disp(['ELCR : ' num2str(ELCR)])
disp(['CM : ' num2str(CM)])
disp(['Safe : ' num2str(Safe)])
%         save([ Cur_Scenario_Selection '_Fallback_GT_num'],'Fallback_GT_num')

cd([CarMaker_Project_Path '\Data\TestRun'])
delete([Cur_Scenario_Selection '_ESL'])
delete([Cur_Scenario_Selection '_ESR'])
delete([Cur_Scenario_Selection '_ESS'])
delete([Cur_Scenario_Selection '_ELCL'])
delete([Cur_Scenario_Selection '_ELCR'])



cd(Data_Path)
Data_Path_Dir = dir;

for Folder_Index = 1 : length(Data_Path_Dir)
    if contains(Data_Path_Dir(Folder_Index).name,[Cur_Scenario_Selection '_ESL'])
        rmdir([Cur_Scenario_Selection '_ESL'], 's')
    elseif contains(Data_Path_Dir(Folder_Index).name,[Cur_Scenario_Selection '_ESR'])
        rmdir([Cur_Scenario_Selection '_ESR'], 's')
    elseif contains(Data_Path_Dir(Folder_Index).name,[Cur_Scenario_Selection '_ESS'])
        rmdir([Cur_Scenario_Selection '_ESS'], 's')
    elseif contains(Data_Path_Dir(Folder_Index).name,[Cur_Scenario_Selection '_ELCL'])
        rmdir([Cur_Scenario_Selection '_ELCL'], 's')
    elseif contains(Data_Path_Dir(Folder_Index).name,[Cur_Scenario_Selection '_ELCR'])
        rmdir([Cur_Scenario_Selection '_ELCR'], 's')
    end
end

disp('AES GT complete')

