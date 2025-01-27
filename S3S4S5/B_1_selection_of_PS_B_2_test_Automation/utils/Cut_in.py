import os 
from Utils.detail_query import *
from Utils.base_utils import *
import scipy.io as sio
import matplotlib.pyplot as plt
from tqdm import tqdm


def Cut_in_from_Left(Query = {"$and":[{"annotationType":"manual"},{"dynamic.story.event.actors.maneuver":{"$regex":"LC","$options":"i"}}]}, debug_csv = True):
    
    os.system('cls')
    print("Cut_in_from_Left")
    db = Detail_Query(_my_query=Query)
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"탐색된 데이터 수 : {len(db.Documents)}")
    
    # Config 파일 읽기
    
    FOT_Configdir = './Configs/FOT.json'
    RG3_Configdir = './Configs/RG3.json'
    CN7_Configdir = './Configs/CN7.json'
    
    FOT = Read_config(FOT_Configdir)
    RG3 = Read_config(RG3_Configdir)
    CN7 = Read_config(CN7_Configdir)
    
    # [데이터 프레임 생성]
    total_cut_in_df             = pd.DataFrame(columns=["initial_velocity_ego","initial_velocity_target","duration_cut_in","acceleration_target_during_cut_in","r_cut_in"])
    debug_total_cut_in_df       = pd.DataFrame(columns=["initial_velocity_ego","initial_velocity_target","duration_cut_in","acceleration_target_during_cut_in","r_cut_in",'frameIndex','directory','ID','recognition','maneuver'])
    result_cut_in_df            = pd.DataFrame(columns=["v_ego","v_target","t_cut_in","a_target","R_cut_in"])
    for doc in tqdm(db.Documents, desc = "Cut-in Extracting",ascii = True):    
        
        # [RG3 CN7 구분]
        vehicle = "NOTHING"
        vehicle = Vehicle_type_check(doc['directory']['perception']['SF'])
        if vehicle == None:
            continue
        CAR = get_vehicle_dict(vehicle,RG3,CN7)
        
        # [수정된 디렉토리 생성]
        
        
        if vehicle == "RG3":
            splited_dir = doc['directory']['perception']['SF'].split("\mat")[1].split("\\")
            new_dir =r"\\192.168.75.251\Shares\FOT_Genesis Data_1\mat" + "\\" + splited_dir[1] + "\\" + splited_dir[2]+ "\\" +splited_dir[3] + "\\" +splited_dir[4]            

            # # [Mat 파일 읽기]
            # mat_data = sio.loadmat(new_dir)
        elif vehicle == "CN7":
            splited_dir = doc['directory']['perception']['SF'].split("\Rosbag2Mat")[1].split("\\")
            new_dir =r"\\192.168.75.251\Shares\FOT_Avante Data_1\Rosbag2Mat" + "\\" + splited_dir[1] + "\\" + splited_dir[2]+ "\\" +splited_dir[3] + "\\" +splited_dir[4]            
            
        # [Mat 파일 읽기]
        mat_data = sio.loadmat(new_dir)
        
        
        # [Event 정보 추출]
        event_df                    = pd.DataFrame(columns = ['frameIndex','recognition','maneuver','ID','maneuver_duration'])
        for event in doc['dynamic']['story']['event']:
            tmp_maneuver                    = event['actors']['maneuver']
            tmp_frame                       = event['frameIndex']
            tmp_recognition                 = event['actors']['recognition']
            tmp_id                          = event['actors']['participantID']                       
            event_df.loc[event_df.shape[0]] = [tmp_frame,tmp_recognition,tmp_maneuver,tmp_id,0]  
        
        # [Maneuver Duration 추출]
        for idx,row in event_df.iterrows():
            
            tmp_frame                       = row['frameIndex']
            tmp_id                          = row['ID']
            tmp_maneuver                    = row['maneuver']
            tmp_id_df                       = event_df.loc[(event_df['ID'] == tmp_id) & (event_df['frameIndex'] >= tmp_frame)]
            
            # [종료 인덱스가 있는 경우] 
            if (tmp_id_df.shape[0] > 1) :
                tmp_end_frame = tmp_id_df.iloc[1]['frameIndex']
                event_df.loc[idx,'maneuver_duration'] = tmp_end_frame - tmp_frame
            
            # [종료 인덱스가 없는 경우 그러면서 maneuver가 LC를 포함하는 경우 # 걍 종료 인덱스 없으면 다 패쓰]
            elif (tmp_id_df.shape[0] <= 1) and ('LC' in tmp_id_df.iloc[0]['maneuver']):
                # [데이터가 거의 끝나가는 부분에 있다면 그냥 패쓰? or 120으로 채워넣기 or 데이터 끝나는 시점으로 채워넣기 (일단 120으로 채워넣기로 진행함)]
                event_df.loc[idx,'maneuver_duration'] = FOT['NONE_MANEUVER_DURATION']
            
            # [종료 인덱스가 없는 경우 그러면서 maneuver가 LC를 포함하지 않는 경우 STP,] 
            elif (tmp_id_df.shape[0] <= 1) and ('LC' not in tmp_id_df.iloc[0]['maneuver']) :
                event_df.loc[idx,'maneuver_duration'] = FOT['MAX_MANEUVER_DURATION']       
        

        for event in doc['dynamic']['story']['event']:
            tmp_maneuver                    = event['actors']['maneuver']
            tmp_frame                       = event['frameIndex']
            tmp_recognition                 = event['actors']['recognition']
            tmp_id                          = event['actors']['participantID']           
    
            # lane_change_event_df = event_df[(event_df['maneuver'].str.contains('LCR') & event_df['recognition'].str.contains('FVL')) | \
            #     (event_df['maneuver'].str.contains('LCL') & event_df['recognition'].str.contains('FVR'))]

            lane_change_event_df = event_df[(event_df['maneuver'].str.contains('LCR') & event_df['recognition'].str.contains('FVL'))]            
            
            if lane_change_event_df.shape[0] > 0: # 이벤트가 존재하는 경우
                for index, row in lane_change_event_df.iterrows():  
                    tmp_frame                   = row['frameIndex']
                    tmp_recognition             = row['recognition']
                    tmp_maneuver                = row['maneuver']
                    tmp_id                      = row['ID']
                    tmp_duration                = row['maneuver_duration']
                    
                    tmp_result = mat_data['SF_PP'][0,0]
                
                    tmp_ego    = mat_data['SF_PP'][0,0]['In_Vehicle_Sensor_sim']
                    
                    tmp_relative_distance                           = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_TRACKING_DICT"]['REL_POS_X'], tmp_id - 1, tmp_frame - 1]    
                    # tmp_acceleration_of_preceding                   = tmp_result['Fusion_Track_Maneuver'][FUSION_TRACK_MEASURE_DICT['REL_ACC_X'] , tmp_id - 1, tmp_frame - 1]   
                    # tmp_initial_velocity_of_ith_car                 = NONE_MANEUVER_DURATION
                    tmp_initial_velocity_ego                        = tmp_ego[: , mat_data['SF_PP'][0,0]['IN_VEHICLE_SENSOR'][0,0]['PREPROCESSING'][0,0]['VEHICLE_SPEED'][0,0] -1][tmp_frame - 1] * FOT["m2km"]
                    tmp_initial_velocity_target                     = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_MEASURE_DICT"]['ABS_VEL'] , tmp_id - 1, tmp_frame - 1] * FOT["m2km"] 
                    tmp_initial_accel_ego                           = tmp_ego[: , mat_data['SF_PP'][0,0]['IN_VEHICLE_SENSOR'][0,0]['PREPROCESSING'][0,0]['LONG_ACC'][0,0] -1][tmp_frame - 1]
                    tmp_duration_cut_in                             = tmp_duration / 20 # 1초당 20프레임
                    tmp_acceleration_target_during_cut_in           = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_MEASURE_DICT"]['REL_ACC_X'] , tmp_id - 1, tmp_frame - 1] + tmp_initial_accel_ego
                    r_cut_in                                        = tmp_relative_distance
                    
                    total_cut_in_df.loc[total_cut_in_df.shape[0]] = [tmp_initial_velocity_ego, tmp_initial_velocity_target, tmp_duration_cut_in, tmp_acceleration_target_during_cut_in, r_cut_in]     
                    debug_total_cut_in_df.loc[debug_total_cut_in_df.shape[0]] = [tmp_initial_velocity_ego, tmp_initial_velocity_target, tmp_duration_cut_in, tmp_acceleration_target_during_cut_in, r_cut_in, tmp_frame, new_dir,tmp_id,tmp_recognition,tmp_maneuver]           

    ## [Cut-in filtering]
    CSV_SAVE_DIR = './Data/LK_CIL_ST'
    if not os.path.exists(CSV_SAVE_DIR):
        os.makedirs(CSV_SAVE_DIR)
    
    # [debug용 데이터 저장]
    filtered_debug_total_cut_in = debug_total_cut_in_df.copy()
    filtered_debug_total_cut_in = filtered_debug_total_cut_in.drop_duplicates()
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['duration_cut_in'] >= 200, 'duration_cut_in'] = None # cutin duration이 10초 이상인 경우는 제거, 200프레임 = 10초
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['r_cut_in'] >= 51, 'r_cut_in'] = None # ROI 50m밖의 데이터는 제거
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['r_cut_in'] <= 0, 'r_cut_in'] = None # 전방에서 컷인 하는 데이터만 추출
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['duration_cut_in'] < 1 , 'duration_cut_in'] = None  # cutin duration이 0.05초 이하인 경우는 제거, 1프레임 = 0.05초, 그보다 작은 경우는 노이즈로 판단
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['acceleration_target_during_cut_in'] > 10 , 'acceleration_target_during_cut_in'] = None
    
    if debug_csv == True:
        filtered_debug_total_cut_in.to_csv(os.path.join(CSV_SAVE_DIR,'debug_cut_in_result.csv'))

    # [결과 데이터 저장]
    filtered_total_cut_in = total_cut_in_df.copy() 
    filtered_total_cut_in.loc[filtered_total_cut_in['duration_cut_in'] >= 200, 'duration_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['r_cut_in'] >= 51, 'r_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['r_cut_in'] < 0, 'r_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['duration_cut_in'] < 1 , 'duration_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['acceleration_target_during_cut_in'] > 10 , 'acceleration_target_during_cut_in'] = None
    
    # filtered_debug_total_cut_in.to_csv(os.path.join(CSV_SAVE_DIR,'cut_in_result.csv'))
    
    result_cut_in_df.loc[result_cut_in_df.shape[0]] = [filtered_total_cut_in['initial_velocity_ego'].min(),filtered_total_cut_in['initial_velocity_target'].min(),filtered_total_cut_in['duration_cut_in'].min(),filtered_total_cut_in['acceleration_target_during_cut_in'].min(),filtered_total_cut_in['r_cut_in'].min()]
    result_cut_in_df.loc[result_cut_in_df.shape[0]] = [filtered_total_cut_in['initial_velocity_ego'].max(),filtered_total_cut_in['initial_velocity_target'].max(),filtered_total_cut_in['duration_cut_in'].max(),filtered_total_cut_in['acceleration_target_during_cut_in'].max(),filtered_total_cut_in['r_cut_in'].max()]
    result_cut_in_df.to_csv(os.path.join(CSV_SAVE_DIR,'LK_CIL_ST.csv'),index=False)
    
    result_cut_in_df            = pd.DataFrame(columns=["v_ego","v_target","t_cut_in","a_target","R_cut_in"])
    
    
    # # [Visualization]
    # sns.pairplot(filtered_total_cut_in)
    # plt.show()


def Cut_in_from_Right(Query = {"$and":[{"annotationType":"manual"},{"dynamic.story.event.actors.maneuver":{"$regex":"LC","$options":"i"}}]}, debug_csv = True):
    
    os.system('cls')
    print("Cut_in_from_Right")
    db = Detail_Query(_my_query=Query)
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"탐색된 데이터 수 : {len(db.Documents)}")
    
    # Config 파일 읽기
    
    FOT_Configdir = './Configs/FOT.json'
    RG3_Configdir = './Configs/RG3.json'
    CN7_Configdir = './Configs/CN7.json'
    
    FOT = Read_config(FOT_Configdir)
    RG3 = Read_config(RG3_Configdir)
    CN7 = Read_config(CN7_Configdir)
    
    # [데이터 프레임 생성]
    total_cut_in_df             = pd.DataFrame(columns=["initial_velocity_ego","initial_velocity_target","duration_cut_in","acceleration_target_during_cut_in","r_cut_in"])
    debug_total_cut_in_df       = pd.DataFrame(columns=["initial_velocity_ego","initial_velocity_target","duration_cut_in","acceleration_target_during_cut_in","r_cut_in",'frameIndex','directory','ID','recognition','maneuver'])
    result_cut_in_df            = pd.DataFrame(columns=["initial_velocity_ego","initial_velocity_target","duration_cut_in","acceleration_target_during_cut_in","r_cut_in"])
    for doc in tqdm(db.Documents, desc = "Cut-in Extracting",ascii = True):    
        
        # [RG3 CN7 구분]
        vehicle = "NOTHING"
        vehicle = Vehicle_type_check(doc['directory']['perception']['SF'])
        if vehicle == None:
            continue
        CAR = get_vehicle_dict(vehicle,RG3,CN7)
        
        # [수정된 디렉토리 생성]
        
        
        if vehicle == "RG3":
            splited_dir = doc['directory']['perception']['SF'].split("\mat")[1].split("\\")
            new_dir =r"\\192.168.75.251\Shares\FOT_Genesis Data_1\mat" + "\\" + splited_dir[1] + "\\" + splited_dir[2]+ "\\" +splited_dir[3] + "\\" +splited_dir[4]            

            # # [Mat 파일 읽기]
            # mat_data = sio.loadmat(new_dir)
        elif vehicle == "CN7":
            splited_dir = doc['directory']['perception']['SF'].split("\Rosbag2Mat")[1].split("\\")
            new_dir =r"\\192.168.75.251\Shares\FOT_Avante Data_1\Rosbag2Mat" + "\\" + splited_dir[1] + "\\" + splited_dir[2]+ "\\" +splited_dir[3] + "\\" +splited_dir[4]            
            
        # [Mat 파일 읽기]
        mat_data = sio.loadmat(new_dir)
        
        
        # [Event 정보 추출]
        event_df                    = pd.DataFrame(columns = ['frameIndex','recognition','maneuver','ID','maneuver_duration'])
        for event in doc['dynamic']['story']['event']:
            tmp_maneuver                    = event['actors']['maneuver']
            tmp_frame                       = event['frameIndex']
            tmp_recognition                 = event['actors']['recognition']
            tmp_id                          = event['actors']['participantID']                       
            event_df.loc[event_df.shape[0]] = [tmp_frame,tmp_recognition,tmp_maneuver,tmp_id,0]  
        
        # [Maneuver Duration 추출]
        for idx,row in event_df.iterrows():
            
            tmp_frame                       = row['frameIndex']
            tmp_id                          = row['ID']
            tmp_maneuver                    = row['maneuver']
            tmp_id_df                       = event_df.loc[(event_df['ID'] == tmp_id) & (event_df['frameIndex'] >= tmp_frame)]
            
            # [종료 인덱스가 있는 경우] 
            if (tmp_id_df.shape[0] > 1) :
                tmp_end_frame = tmp_id_df.iloc[1]['frameIndex']
                event_df.loc[idx,'maneuver_duration'] = tmp_end_frame - tmp_frame
            
            # [종료 인덱스가 없는 경우 그러면서 maneuver가 LC를 포함하는 경우 # 걍 종료 인덱스 없으면 다 패쓰]
            elif (tmp_id_df.shape[0] <= 1) and ('LC' in tmp_id_df.iloc[0]['maneuver']):
                # [데이터가 거의 끝나가는 부분에 있다면 그냥 패쓰? or 120으로 채워넣기 or 데이터 끝나는 시점으로 채워넣기 (일단 120으로 채워넣기로 진행함)]
                event_df.loc[idx,'maneuver_duration'] = FOT['NONE_MANEUVER_DURATION']
            
            # [종료 인덱스가 없는 경우 그러면서 maneuver가 LC를 포함하지 않는 경우 STP,] 
            elif (tmp_id_df.shape[0] <= 1) and ('LC' not in tmp_id_df.iloc[0]['maneuver']) :
                event_df.loc[idx,'maneuver_duration'] = FOT['MAX_MANEUVER_DURATION']       
        

        for event in doc['dynamic']['story']['event']:
            tmp_maneuver                    = event['actors']['maneuver']
            tmp_frame                       = event['frameIndex']
            tmp_recognition                 = event['actors']['recognition']
            tmp_id                          = event['actors']['participantID']           
    
            # lane_change_event_df = event_df[(event_df['maneuver'].str.contains('LCR') & event_df['recognition'].str.contains('FVL')) | \
            #     (event_df['maneuver'].str.contains('LCL') & event_df['recognition'].str.contains('FVR'))]

            lane_change_event_df = event_df[(event_df['maneuver'].str.contains('LCL') & event_df['recognition'].str.contains('FVR'))]            
            
            if lane_change_event_df.shape[0] > 0: # 이벤트가 존재하는 경우
                for index, row in lane_change_event_df.iterrows():  
                    tmp_frame                   = row['frameIndex']
                    tmp_recognition             = row['recognition']
                    tmp_maneuver                = row['maneuver']
                    tmp_id                      = row['ID']
                    tmp_duration                = row['maneuver_duration']
                    
                    tmp_result = mat_data['SF_PP'][0,0]
                
                    tmp_ego    = mat_data['SF_PP'][0,0]['In_Vehicle_Sensor_sim']
                    
                    tmp_relative_distance                           = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_TRACKING_DICT"]['REL_POS_X'], tmp_id - 1, tmp_frame - 1]    
                    # tmp_acceleration_of_preceding                   = tmp_result['Fusion_Track_Maneuver'][FUSION_TRACK_MEASURE_DICT['REL_ACC_X'] , tmp_id - 1, tmp_frame - 1]   
                    # tmp_initial_velocity_of_ith_car                 = NONE_MANEUVER_DURATION
                    tmp_initial_velocity_ego                        = tmp_ego[: , mat_data['SF_PP'][0,0]['IN_VEHICLE_SENSOR'][0,0]['PREPROCESSING'][0,0]['VEHICLE_SPEED'][0,0] -1][tmp_frame - 1] * FOT["m2km"]
                    tmp_initial_velocity_target                     = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_MEASURE_DICT"]['ABS_VEL'] , tmp_id - 1, tmp_frame - 1] * FOT["m2km"] 
                    tmp_initial_accel_ego                           = tmp_ego[: , mat_data['SF_PP'][0,0]['IN_VEHICLE_SENSOR'][0,0]['PREPROCESSING'][0,0]['LONG_ACC'][0,0] -1][tmp_frame - 1]
                    tmp_duration_cut_in                             = tmp_duration / 20 # 1초당 20프레임
                    tmp_acceleration_target_during_cut_in           = tmp_result['Fusion_Track_Maneuver'][CAR["FUSION_TRACK_MEASURE_DICT"]['REL_ACC_X'] , tmp_id - 1, tmp_frame - 1] + tmp_initial_accel_ego
                    r_cut_in                                        = tmp_relative_distance
                    
                    total_cut_in_df.loc[total_cut_in_df.shape[0]] = [tmp_initial_velocity_ego, tmp_initial_velocity_target, tmp_duration_cut_in, tmp_acceleration_target_during_cut_in, r_cut_in]     
                    debug_total_cut_in_df.loc[debug_total_cut_in_df.shape[0]] = [tmp_initial_velocity_ego, tmp_initial_velocity_target, tmp_duration_cut_in, tmp_acceleration_target_during_cut_in, r_cut_in, tmp_frame, new_dir,tmp_id,tmp_recognition,tmp_maneuver]           

    ## [Cut-in filtering]
    CSV_SAVE_DIR = './result/LK_CIR_ST'
    if not os.path.exists(CSV_SAVE_DIR):
        os.makedirs(CSV_SAVE_DIR)
    
    # [debug용 데이터 저장]
    filtered_debug_total_cut_in = debug_total_cut_in_df.copy()
    filtered_debug_total_cut_in = filtered_debug_total_cut_in.drop_duplicates()
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['duration_cut_in'] >= 200, 'duration_cut_in'] = None # cutin duration이 10초 이상인 경우는 제거, 200프레임 = 10초
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['r_cut_in'] >= 51, 'r_cut_in'] = None # ROI 50m밖의 데이터는 제거
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['r_cut_in'] <= 0, 'r_cut_in'] = None # 전방에서 컷인 하는 데이터만 추출
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['duration_cut_in'] < 1 , 'duration_cut_in'] = None  # cutin duration이 0.05초 이하인 경우는 제거, 1프레임 = 0.05초, 그보다 작은 경우는 노이즈로 판단
    filtered_debug_total_cut_in.loc[filtered_debug_total_cut_in['acceleration_target_during_cut_in'] > 10 , 'acceleration_target_during_cut_in'] = None
        
    if debug_csv == True:
        filtered_debug_total_cut_in.to_csv(os.path.join(CSV_SAVE_DIR,'debug_cut_in_result.csv'))
        

    # [결과 데이터 저장]
    filtered_total_cut_in = total_cut_in_df.copy() 
    filtered_total_cut_in.loc[filtered_total_cut_in['duration_cut_in'] >= 200, 'duration_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['r_cut_in'] >= 51, 'r_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['r_cut_in'] < 0, 'r_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['duration_cut_in'] < 1 , 'duration_cut_in'] = None
    filtered_total_cut_in.loc[filtered_total_cut_in['acceleration_target_during_cut_in'] > 10 , 'acceleration_target_during_cut_in'] = None
    
    # filtered_debug_total_cut_in.to_csv(os.path.join(CSV_SAVE_DIR,'cut_in_result.csv'))
    
    result_cut_in_df.loc[result_cut_in_df.shape[0]] = [filtered_total_cut_in['initial_velocity_ego'].min(),filtered_total_cut_in['initial_velocity_target'].min(),filtered_total_cut_in['duration_cut_in'].min(),filtered_total_cut_in['acceleration_target_during_cut_in'].min(),filtered_total_cut_in['r_cut_in'].min()]
    result_cut_in_df.loc[result_cut_in_df.shape[0]] = [filtered_total_cut_in['initial_velocity_ego'].max(),filtered_total_cut_in['initial_velocity_target'].max(),filtered_total_cut_in['duration_cut_in'].max(),filtered_total_cut_in['acceleration_target_during_cut_in'].max(),filtered_total_cut_in['r_cut_in'].max()]
    result_cut_in_df.to_csv(os.path.join(CSV_SAVE_DIR,'LK_CIR_ST.csv'),index=False)    