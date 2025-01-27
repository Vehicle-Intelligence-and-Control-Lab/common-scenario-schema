import json
import os
import scipy
import h5py
import numpy as np
import pandas as pd
from colorama import Fore
from tqdm import tqdm
import glob
from Utils.schema_for_carmaker_1_1 import *
import natsort
from pathlib import Path



##################### Setting ##########################

# 생성할 Logical scenario catalog
SOTIF = 1
AES = 0
# Logical scenario 생성 토글
single_toggle = 0              # 1:ON  0:OFF
i = 11                          # 생성할 Logical scenario 번호 (single toggle에 해당, 가장 아래 번호 리스트 확인 가능)

multiple_toggle = 1             # 1:ON  0:OFF

# 파일 경로
# registration_dir = r"D:\Shares\MORAI Scenario Data\SOTIF Catalogue\MORAI Project\Registration"
save_dir = r"\\192.168.75.251\Shares\Precrash Scenario Data\Scenario Catalog for Car to Car\Json"

########################################################



# def make_CSS(testrun_dir, simulation_name, registration_dir, save_dir):
def make_CSS(testrun_dir, simulation_name, save_dir):
        
    path = './Configs/schema_v1.1.json'
    css = read_json(path)
    
    file_name = simulation_name + ".json"
    file_path = os.path.join(save_dir, file_name)

    # tmk = Makejson(testrun_dir, registration_dir, simulation_name)
    tmk = Makejson(testrun_dir, simulation_name)

    
    #admin
    css['admin']['filePath']['raw'] = tmk.testrun_file_path.replace('D:', '\\\\192.168.75.251')
    css['admin']['filePath']['exported'] = " "
    # css['admin']['filePath']['registration'] = registration_dir.replace('D:', '\\\\192.168.75.251')
    css['admin']['filePath']['registration'] = ""
    css['admin']['filePath']['perception']['LDT'] = " " 
    css['admin']['filePath']['perception']['SF'] = " "
    css['admin']['filePath']['perception']['recognition'] = " "
    css['admin']['filePath']['Decision']['maneuver'] = " "
    css['admin']['date'] = " "
    css['admin']['dataType'] = tmk.dataType
    css['admin']['travelTime'] = " "
    css['admin']['travelDistance'] = " "
    css['admin']['fileSize'] =" "
    css['admin']['geoReference']['type'] = " "
    css['admin']['geoReference']['coordinates'] = " "
    css['admin']['frameInterval']['frameStart'] = " "
    css['admin']['frameInterval']['frameEnd'] = " "
    css['admin']['sampleTime'] = " "
    css['admin']['schemaVersion'] = tmk.schemaVersion
    css['admin']['comment'] = " "
    css['admin']['CMGT'] = " "
    css['admin']['CAGT'] = " "
    css['admin']['sensorConfiguration'] = " "
    css['admin']['qualityOfData'] = " "
    
    #dynamic
    css['dynamic'] = " "
    
    #surroundings
    css['surroundings'] = " "
    
    #scenarios
    css['scenarios']['dataSources']['expertKnowledge'] = []
    # for expert in tmk.expertKnowledge:
    #     css['scenarios']['dataSources']['expertKnowledge'].append(
    #         expert
    # )


    css['scenarios']['dataSources']['accidentData'] = []
    
    # for data in tmk.accidentData:
    #     css['scenarios']['dataSources']['accidentData'].append(
    #         data
    #     )
    
    css['scenarios']['entities'] = []
    # print(tmk.entities)
    # for entity in tmk.entities:
    #     css['scenarios']['entities'].append(
    #         entity
    #     )

    css['scenarios']['storyboard']['name'] = tmk.scenario

    css['scenarios']['storyboard']['init']['actions']['privates'] = []
    # for private in tmk.privates:
    #     css['scenarios']['storyboard']['init']['actions']['privates'].append(
    #         private
    #     )
    
    css['scenarios']['storyboard']['stories']['maneuverGroups'] = []
    # for maneuver_group in tmk.maneuver_groups:
    #     css['scenarios']['storyboard']['stories']['maneuverGroups'].append(
    #         maneuver_group
    #     )
    
    #parameterSpace
    css['parameterSpace']['reduceParam'] = " "
    css['parameterSpace']['samplingMethod'] = " "
    css['parameterSpace']['parameters'] = []
    # for paramter in tmk.parameters:
    #     css['parameterSpace']['parameters'].append(
    #         paramter
    #     )
            
    #road
    css['road']['roadName'] = " "
    css['road']['A2_LINK']['ID'] = " "
    css['road']['A2_LINK']['AdminCode'] = " " 
    css['road']['A2_LINK']['RoadRank'] = " "
    css['road']['A2_LINK']['RoadType'] = " "
    css['road']['A2_LINK']['LinkType'] = " "

    with open(file_path, 'w', encoding='utf-8') as file:
        json.dump(css, file, indent=2, ensure_ascii=False)

    # jsonList = natsort.natsorted(glob.glob(save_dir + '\\*_tmp.json'))
    # tmp=[]
    # for i in range(np.size(jsonList)):
    #             with open(jsonList[i]) as file:
    #                 data = json.load(file)
    #                 tmp.append(data)

    # with open(save_dir + '\\' + vehicle_data + '.json' ,"w") as new_file:
    #     json.dump([tmp[i] for i in range(np.size(jsonList))] , new_file,indent='\t')
                
            
    # for file in jsonList:
    #     if file.endswith('_tmp.json'):
    #         os.remove(file)

# def check_is_annotation_file(mat_file):
    
#     mat_name = mat_file.split(".mat")[0]
#     annoatation = os.path.join(r'\\192.168.75.251\Shares\FOT_Avante Data_1\Rosbag2Mat', vehicle_data, 'Registration', 'Annotation')
    
#     for idx in os.listdir(annoatation):
#         if mat_name in idx:
#             return True
        
#    return False

if __name__ == "__main__":

    # Logical scenario catalog
    
    if SOTIF == 1:                    
        testrun_dir=r"\\192.168.75.251\Shares\Precrash Scenario Data\Scenario Catalog for Car to Car\CarMaker Project\Data\TestRun"    
        simulation_datas = ["LCL_LF_ST",                     # 0
                            "LCR_LF_ST",                     # 1
                            "LK_BWD_ST",                     # 2
                            "LK_CIL_CU",                     # 3
                            "LK_CIL_SH",                     # 4
                            "LK_CIL_ST",                     # 5
                            "LK_CIR_CU",                     # 6
                            "LK_CIR_MER",                    # 7
                            "LK_CIR_ST",                     # 8
                            "LK_COL_STP_SH",                   # 9  
                            "LK_COL_STP_ST",                      # 10
                            "LK_COR_STP_CU",                      # 11
                            "LK_COR_STP_ST",                     # 12
                            "LK_LF_SH",                     # 13
                            "LK_LF_ST",                       # 14
                            "LK_LFL2R_IN",                       # 15
                            "LK_LFR2L_IN",                       # 16
                            "LK_LTOD2R_IN",                       # 17
                            "LK_OVE_CU",                       # 18
                            "LK_OVE_ST",                       # 19
                            "LK_RTR2SD_IN",                       # 20
                            "LK_STP_CU",                      # 21
                            "LK_STP_ST",                        # 22
                            "LT_LFL2R_IN",                       # 23
                            "LT_LFR2L_IN",                       # 24
                            "LT_OVE_IN",                      # 25
                            "RT_LFL2R_IN",                       # 26
                            "UT_LF_ST",                       # 27
                            "UT_OVE_ST",          # 28
                            ]

    if AES == 1:                    
        testrun_dir=r"\\192.168.75.251\Shares\AES Scenario Data\Simulation\PSD-17-CM11FB7(1120)\TestRun"    
        simulation_datas = ["LK_CIL_CU",             # 0
                            "LK_CIL_SH",                     # 1
                            "LK_CIL_ST",                     # 2
                            "LK_CIR_CU",                     # 3
                            "LK_CIR_MER",                     # 4
                            "LK_CIR_ST",                 # 5
                            "LK_COL_STP_SH",                 # 6
                            "LK_COL_STP_ST",                      # 7
                            "LK_COR_STP_CU",                     # 8
                            "LK_COR_STP_ST",                     # 9
                            "LK_LF_SH",                   # 10  
                            "LK_LF_ST",                      # 11
                            "LK_OVE_CU",                      # 12
                            "LK_OVE_ST",                     # 13
                            "LK_STP_CU",                     # 14
                            "LK_STP_ST",                       # 15
                            ]
    
    # 하나의 시뮬레이션 데이터에 대해 확인할 때 사용
    if single_toggle == 1:
        print(simulation_datas[i] + '.json 생성중...')
        # make_CSS(testrun_dir, simulation_datas[i], registration_dir, save_dir)
        make_CSS(testrun_dir, simulation_datas[i], save_dir)
        print(simulation_datas[i] + '.json 완성!!!')
        print('-'*30)
    
    # 여러개의 시뮬레이션 데이터에 대해 확인할 때 사용
    elif multiple_toggle == 1:   
        for simulation_data in simulation_datas:
            print(simulation_data + '.json 생성중...')
            # make_CSS(testrun_dir,simulation_data, registration_dir, save_dir)
            make_CSS(testrun_dir,simulation_data, save_dir)
            print(simulation_data + '.json 완성!!!')
            print('-'*30)




    