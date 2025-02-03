import os
import sys
import json
from bson import ObjectId
import pandas as pd
from pymongo import MongoClient
from utils.gen_param import GenParam
from utils.reduce_param import ReduceParam
from utils.sample_param import SampleParam
from utils.gen_xosc import XOSCGenerator
from utils.api import api
import pandas as pd
sys.path.append('C:\Program Files\MATLAB\R2023b\extern\engines\python')
import matlab.engine
import subprocess
import shutil



#-------------Setting--------------------------------------------------
num_of_concrete =10
sampling_num = 6
query = {
  "$and": [
    {
      "admin.filePath.raw": {
        "$regex": "LK_CIR_ST",
        "$options": "i"
      }
    },
    {
      "admin.filePath.raw": {
        "$regex": "morai",
        "$options": "i"
      }
    },
    {
      "$or": [
        {
          "admin.filePath.raw": {
            "$regex": "rawPS",
            "$options": "i"
          }
        },
        {
          "admin.dataType": {
            "$regex": "xosc",
            "$options": "i"
          }
        }
      ]
    }
  ]
}


# 시뮬레이션 활성화
toggle_run_simulation = 1  # 1: 활성화, 0: 비활성화


# CarMaker 시뮬레이션 설정
toggle_IDM = 0
toggle_testAutomation = 1
toggle_erg2mat = 1
toggle_genCollisionGT = 1  # 1: 활성화, 0: 비활성화
toggle_genCAGT = 0
toggle_movie_export = 0



#-----------------------------------------------------------------------

# 커스텀 변환 함수 정의
class JSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)  # ObjectId를 문자열로 변환
        return json.JSONEncoder.default(self, obj)



# Connection to the mongoDB
client = MongoClient('mongodb://192.168.75.251:27017/')
db_sotif = client['SOTIF']
db_METIS = client['METIS']
logical_collection = db_sotif['logicalScenario']
# logical_collection = db_METIS['Scenario']
param_collection = db_sotif['parameterSpace']


logical_result = logical_collection.find(query)
for logical_doc in logical_result:
    data_type = logical_doc['admin']['dataType']
    logical_path = logical_doc['admin']['filePath']['raw']
    logical_scenario = logical_path.split('\\')[-1].split('.')[0]


rawPS_result = param_collection.find(query)
rawPS_count = param_collection.count_documents(query)
if rawPS_count != 1:
    print('There are multiple rawPS documents. Please check the data.')
    exit()
for rawPS_doc in rawPS_result:
    rawPS_path = rawPS_doc['admin']['filePath']['raw']
    folder_date = rawPS_path.split('\\')[-2]
    if not '\\\\192.168.75.251' in rawPS_path:
        rawPS_path = rawPS_path.replace('D:', '\\\\192.168.75.251')
    rawPS_df = pd.read_csv(rawPS_path)


    # Generate linear spacing PS
    linear_spacing_PS = GenParam(rawPS_df, sampling_num, 'linear').param_table
    if data_type == 'xosc':
        linear_spacing_PS_dir = f'\\\\192.168.75.251\\Shares\\MORAI Scenario Data\\Scenario Catalog for SOTIF\\MORAI Project\\PS\\{logical_scenario}\\{folder_date}'
        if not os.path.isdir(linear_spacing_PS_dir):
            os.makedirs(linear_spacing_PS_dir)
        linear_spacing_PS_path = os.path.join(linear_spacing_PS_dir,f'{logical_scenario}_LSPS.csv')
        linear_spacing_PS.to_csv(linear_spacing_PS_path, index=False)
    elif data_type == 'testrun':
        if 'Augmented' in logical_path:
            linear_spacing_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Augmented\\PS\\{logical_scenario}\\{folder_date}'
        elif 'IDM' in logical_path:
            linear_spacing_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for IDM\\PS\\{logical_scenario}\\{folder_date}'
        elif 'VRU' in logical_path:
            linear_spacing_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Precrash Scenario(Car-to-VRU)\\PS\\{logical_scenario}\\{folder_date}'
        else:
            linear_spacing_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Car to Car\\PS\\{logical_scenario}\\{folder_date}'
        if not os.path.isdir(linear_spacing_PS_dir):
            os.makedirs(linear_spacing_PS_dir)
        linear_spacing_PS_path = os.path.join(linear_spacing_PS_dir,f'{logical_scenario}_LSPS.csv')
        linear_spacing_PS.to_csv(linear_spacing_PS_path, index=False)


    # Reducing the number of PS
    reducing_PS = ReduceParam(linear_spacing_PS, logical_scenario, 'SVM').reduced_param_table
    if reducing_PS is None:
        pass
    else:
        if data_type == 'xosc':
            reducing_PS_path = f'\\\\192.168.75.251\\Shares\\MORAI Scenario Data\\Scenario Catalog for SOTIF\\MORAI Project\\PS\\{logical_scenario}\\{folder_date}\\{logical_scenario}_RPS.csv'
            reducing_PS.to_csv(reducing_PS_path, index=False)
        elif data_type == 'testrun':
            if 'Augmented' in logical_path:
                reducing_PS_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Augmented\\PS\\{logical_scenario}\\{folder_date}\\{logical_scenario}_RPS.csv'
            elif 'IDM' in logical_path:
                reducing_PS_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for IDM\\PS\\{logical_scenario}\\{folder_date}\\{logical_scenario}_RPS.csv'
            elif 'VRU' in logical_path:
                reducing_PS_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for IDM\\PS\\{logical_scenario}\\{folder_date}\\{logical_scenario}_RPS.csv'
            else:
                reducing_PS_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Car to Car\\PS\\{logical_scenario}\\{folder_date}\\{logical_scenario}_RPS.csv'
            reducing_PS.to_csv(reducing_PS_path, index=False)


    # Randomly sampling PS
    if reducing_PS is not None:
        sampled_PS = SampleParam(reducing_PS, num_of_concrete).sampled_param_table
    else:
        sampled_PS = SampleParam(linear_spacing_PS, num_of_concrete).sampled_param_table
    if data_type == 'xosc':
        sampled_json_path = f'\\\\192.168.75.251\\Shares\\MORAI Scenario Data\\Scenario Catalog for SOTIF\\MORAI Project\\Json\\{logical_scenario}\\{folder_date}\\{logical_scenario}_SPS.json'
        sampled_PS_dir = f'\\\\192.168.75.251\\Shares\\MORAI Scenario Data\\Scenario Catalog for SOTIF\\MORAI Project\\PS\\{logical_scenario}\\{folder_date}'
        sampled_PS_path = os.path.join(sampled_PS_dir, f'{logical_scenario}_SPS.csv')
        sampled_PS.to_csv(sampled_PS_path, index=False)
    elif data_type == 'testrun':
        if 'Augmented' in logical_path:
            sampled_json_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Augmented\\Json\\{logical_scenario}\\{folder_date}\\{logical_scenario}_SPS.json'
            sampled_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Augmented\\PS\\{logical_scenario}\\{folder_date}'
        elif 'IDM' in logical_path:
            sampled_json_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for IDM\\Json\\{logical_scenario}\\{folder_date}\\{logical_scenario}_SPS.json'
            sampled_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for IDM\\PS\\{logical_scenario}\\{folder_date}'
        elif 'VRU' in logical_path:
            sampled_json_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Precrash Scenario(Car-to-VRU)\\Json\\{logical_scenario}\\{folder_date}\\{logical_scenario}_SPS.json'
            sampled_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Precrash Scenario(Car-to-VRU)\\PS\\{logical_scenario}\\{folder_date}'
        else:
            sampled_json_path = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Car to Car\\Json\\{logical_scenario}\\{folder_date}\\{logical_scenario}_SPS.json'
            sampled_PS_dir = f'\\\\192.168.75.251\\Shares\\Precrash Scenario Data\\Scenario Catalog for Car to Car\\PS\\{logical_scenario}\\{folder_date}'
        
        sampled_PS_path = os.path.join(sampled_PS_dir, f'{logical_scenario}_SPS.csv')
        sampled_PS.to_csv(sampled_PS_path, index=False)


    # Add PS info to the schema and save it as a json file
    rawPS_doc['admin']['filePath']['raw'] = sampled_PS_path
    if reducing_PS is not None:
        rawPS_doc['parameterSpace']['reduceParam'] = 'true'
    else:
        rawPS_doc['parameterSpace']['reduceParam'] = 'false'
    rawPS_doc['parameterSpace']['samplingMethod'] = 'random'
    for parameter_idx in range(len(rawPS_doc['parameterSpace']['parameters'])):
        parameter = rawPS_doc['parameterSpace']['parameters'][parameter_idx]['name']
        rawPS_doc['parameterSpace']['parameters'][parameter_idx]['genParam']['samplePoint'] = sampling_num
        rawPS_doc['parameterSpace']['parameters'][parameter_idx]['genParam']['value'] = sampled_PS[parameter].values.tolist()
    
    directory = os.path.dirname(sampled_json_path)
    if not os.path.exists(directory):
        os.makedirs(directory)

    with open(sampled_json_path, 'w', encoding='utf-8') as file:
        json.dump(rawPS_doc, file, ensure_ascii=False, indent=2, cls=JSONEncoder)
    json_name = sampled_json_path.split('\\')[-1]
    print('')
    print(f'{json_name} 완성!')


    # Json file to MongoDB
    with open(sampled_json_path, 'r', encoding='utf-8') as file:
        json_data = json.load(file)
    check_query = {
        "admin.filePath.raw": json_data["admin"]["filePath"]["raw"]
    }
    existing_document = param_collection.find_one(check_query)
    if existing_document:
        print(f"중복된 문서가 이미 존재합니다: {existing_document['_id']}")
    else:
        # 중복이 없을 경우 MongoDB에 데이터 삽입
        insert_result = param_collection.insert_one(json_data)
        print(f"MongoDB에 업로드 완료! Document ID: {insert_result.inserted_id}")


    # Create xosc file
    if data_type == 'xosc':
        output_dir = f'\\\\192.168.75.251\\Shares\\MORAI Scenario Data\\Scenario Catalog for SOTIF\\Data\\ConcreteScenario\\{logical_scenario}\\{folder_date}'
        XOSCGenerator(logical_path, sampled_PS_path, output_dir, logical_scenario)


    # Run simulation
    if toggle_run_simulation == 1:
        if data_type == 'xosc':
            api()

        elif data_type == 'testrun':
            eng = matlab.engine.start_matlab()
            main_path = str(os.getcwd())
            # matlab_func_path = os.path.join(main_path, 'utils').replace('\\', '/')
            matlab_func_path = os.path.join(main_path, 'S3S4S5', 'B_1_selection_of_PS_B_2_test_Automation', 'utils').replace('\\', '/')
            eng.addpath(matlab_func_path)
            param_space_path = sampled_PS_path.replace('_SPS', '_Param_Space')
            shutil.copy(sampled_PS_path, param_space_path)
            param_space_path = param_space_path.replace('\\', '/')

            # MATLAB 시나리오 생성 함수 실행
            eng.scenario_generation(matlab_func_path, logical_scenario, param_space_path,
                                            toggle_IDM, toggle_testAutomation, toggle_erg2mat,
                                            toggle_genCollisionGT, toggle_genCAGT, toggle_movie_export, nargout=0)





