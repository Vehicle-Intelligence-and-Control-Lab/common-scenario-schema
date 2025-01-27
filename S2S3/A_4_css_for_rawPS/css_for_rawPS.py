"""
auther: 서도현
update: 2024.02.27
description: 
    v01: rawPS에 대한 json 생성 (서도현)
    v02: rawPS에 대한 경로 및 토그 생성 (김승환)
"""

import json
import sys
import os
import numpy as np
import pandas as pd
from colorama import Fore
from tqdm import tqdm
import glob
from utils.utilsForPS_v1_1 import *
import natsort
from pathlib import Path
from datetime import datetime  # 추가


##################### Setting ##########################

# 생성할 Logical scenario catalog
TESTBED = 0
SOTIF = 1

# Simulator
simulator = 1 # 0: MORAI  1: CarMaker

# Folder date
folder_date = '123121'

# Logical scenario 생성 토글
single_toggle = 1              # 1:ON  0:OFF
i = 58                           # 생성할 Logical scenario 번호 (single toggle에 해당, 가장 아래 번호 리스트 확인 가능)

multiple_toggle = 0             # 1:ON  0:OFF

########################################################




def make_CSS(PS_dir, folder_date, scenario_name, save_dir = None):
    if save_dir is None:
        tmp_dir = PS_dir.split('\\PS')[0]
        raw_PS_dir = os.path.join(PS_dir, scenario_name, folder_date)
        tmp_save_dir = os.path.join(tmp_dir, 'Json', scenario_name, folder_date)
            
    if os.path.isdir(raw_PS_dir):
        # 저장할 경로의 폴더가 없으면 생성
        if os.path.isdir(tmp_save_dir) == False:
            os.makedirs(tmp_save_dir)
            
        path = './configs/schema_v1.1.json'
        css = read_json(path)
        tmp_PS_dir = os.listdir(raw_PS_dir)
        raw_file = [file for file in tmp_PS_dir if 'raw' in file]

        PS_CSV_File_name = raw_file[0].split('.')[0]
        file_name = PS_CSV_File_name + ".json"
        save_dir = os.path.join(tmp_save_dir, file_name)
        tmk = Makejson(PS_dir, PS_CSV_File_name, folder_date)
        
        #admin
        if 'D:' in tmk.PS_file_path :
            css['admin']['filePath']['raw'] = tmk.PS_file_path.replace('D:', '\\\\192.168.75.251')
        else:
            css['admin']['filePath']['raw'] = tmk.PS_file_path
        css['admin']['filePath']['exported'] = " "
        css['admin']['filePath']['registration'] = " "
        css['admin']['filePath']['perception']['LDT'] = " " 
        css['admin']['filePath']['perception']['SF'] = " "
        css['admin']['filePath']['perception']['recognition'] = " "
        css['admin']['filePath']['Decision']['maneuver'] = " "
        css['admin']['date'] = tmk.date
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
        css['scenarios'] = " "
        
        #parameterSpace
        css['parameterSpace']['reduceParam'] = " "
        css['parameterSpace']['samplingMethod'] = " "
        css['parameterSpace']['parameters'] = []
        for paramter in tmk.parameters:
            css['parameterSpace']['parameters'].append(
                paramter
            )
                
        #road
        css['road'] = " "
        #Meta
        css['Meta'] = " "

        with open(save_dir, 'w', encoding='utf-8') as file:
            json.dump(css, file, indent=2, ensure_ascii=False)
        print(scenario_name + '.json 완성!!!')
        print('-'*30)

    else:
        print(Fore.RED + f'{folder_date} 폴더가 존재하지 않습니다.' + Fore.RESET)
        return None


if __name__ == "__main__":

    # Logical scenario catalog
    if TESTBED == 1:
        PS_dir =r"D:\Shares\MORAI Scenario Data\Scenario Catalog for KATRI\MORAI Project\PS"
        simulation_datas = ["Backing",                       # 0 
                            "DoubleParked",                  # 1
                            "EndofTrafficJam",               # 2
                            "FrontVehicleDeceleration",      # 3
                            "IgnoreStopSign",                # 4
                            "IlligalParkingOnNarrowRoad",    # 5
                            "NeighboringLaneOccupied",       # 6
                            "NonSignaledIntersection",       # 7
                            "Over_reliance",                 # 8
                            "Overtaker",                     # 9
                            "Overtaking",                    # 10
                            "PassingEgoVehicle",             # 11
                            "RightTurn",                     # 12
                            "SuddenPedestrianAppear",        # 13
                            "TrafficJam",                    # 14
                            "UnprotectedLeftTurn"            # 15
                            "decVehInAnAdjLane",             # 16
                            ]
    elif SOTIF == 1:      
        if simulator == 0:
            PS_dir =r"\\192.168.75.251\Shares\MORAI Scenario Data\Scenario Catalog for SOTIF\MORAI Project\PS"             
        elif simulator == 1:
            PS_dir =r"\\192.168.75.251\Shares\Precrash Scenario Data\Scenario Catalog for Car to Car\PS"

        simulation_datas = ["LCL_LF_ST",                     # 0
                            "LCR_LF_ST",                     # 1
                            "LK_CIL_ST",                     # 2
                            "LK_CIR_ST",                     # 3
                            "LK_COL_STP_ST",                 # 4
                            "LK_COR_STP_ST",                 # 5
                            "LK_LF_ST",                      # 6
                            "LK_STP_ST",                     # 7
                            "overReliance",                  # 8
                            "nonSignaledIntersection",       # 9
                            "rearCrash",                     # 10
                            "LK_LFL2R_IN",                   # 11
                            "LK_LFR2L_IN",                   # 12
                            "LK_LTOD2R_IN",                  # 13
                            "LK_LTL2SD_IN",                  # 14
                            "LK_PCSL_ST",                    # 15
                            "LK_PCSR_ST",                    # 16
                            "LK_POCL_ST",                    # 17
                            "LK_POCR_ST",                    # 18
                            "LK_PSTP_ST",                    # 19
                            "LK_PWAL_ST",                    # 20
                            "LK_PWAR_ST",                    # 21
                            "LT_LFL2R_IN",                   # 22
                            "LT_OVE_IN",                     # 23
                            "LT_PCSL_IN",                    # 24
                            "LT_PCSR_IN",                    # 25
                            "RT_LFL2R_IN",                   # 26
                            "RT_PCSL_IN",                    # 27
                            "RT_PCSR_IN",                    # 28
                            "drivingAlone",                  # 29
                            "decVehInAnAdjLane",             # 30
                            "LT_LFR2L_IN",                   # 31
                            "LK_BWD_ST",                     # 32
                            "LK_CIL_CU",                     # 33
                            "LK_CIL_SH",                     # 34
                            "LK_CIL_ST",                     # 35 # preCrash
                            "LK_CIR_CU",                     # 36 # preCrash
                            "LK_CIR_MER",                    # 37 # preCrash
                            "LK_CIR_ST",                     # 38 # preCrash
                            "LK_COL_STP_SH",                 # 39 # preCrash
                            "LK_COL_STP_ST",                 # 40 # preCrash
                            "LK_COR_STP_CU",                 # 41 # preCrash
                            "LK_COR_STP_ST",                 # 42 # preCrash
                            "LK_LF_SH",                      # 43 # preCrash
                            "LK_LF_ST",                      # 44 # preCrash
                            "LK_LFL2R_IN",                   # 45 # preCrash
                            "LK_LFR2L_IN",                   # 46 # preCrash
                            "LK_LTOD2R_IN",                  # 47 # preCrash
                            "LK_OVE_CU",                     # 48 # preCrash
                            "LK_OVE_ST",                     # 49 # preCrash
                            "LK_RTR2SD_IN",                  # 50 # preCrash
                            "LK_STP_CU",                     # 51 # preCrash
                            "LK_STP_ST",                     # 52 # preCrash
                            "LT_LFL2R_IN",                   # 53 # preCrash
                            "LT_LFR2L_IN",                   # 54 # preCrash
                            "LT_OVE_IN",                     # 55 # preCrash
                            "RT_LFL2R_IN",                   # 56 # preCrash
                            "UT_LF_ST",                      # 57 # preCrash
                            "UT_OVE_ST",                     # 58 # preCrash
                            ]


    # 하나의 시뮬레이션 데이터에 대해 확인할 때 사용
    if single_toggle == 1:
        print(simulation_datas[i] + '.json 생성중...')
        make_CSS(PS_dir, folder_date, simulation_datas[i])
        print(simulation_datas[i] + '.json 완성!!!')
        print('-'*30)
    
    # 여러개의 시뮬레이션 데이터에 대해 확인할 때 사용
    elif multiple_toggle == 1:   
        for simulation_data in simulation_datas:
            print(simulation_data + '.json 생성중...')
            make_CSS(PS_dir, folder_date, simulation_data)




    