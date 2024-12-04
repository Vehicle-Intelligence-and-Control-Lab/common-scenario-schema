import json
import os
import scipy
import h5py
import numpy as np
import pandas as pd
from colorama import Fore
from tqdm import tqdm
import glob
from datetime import datetime
import xml.etree.ElementTree as ET
import copy


def read_json(path):
    
    with open(path, 'r') as file:
        data = json.load(file)  
    return data

class Makejson():
 
    def __init__(self, PS_dir, PS_CSV_File_name, folder_date): 
        self.PS_file_path, self.PS_file, self.raw_dataType  = self.get_PS_file(PS_dir, PS_CSV_File_name, folder_date)
        self.date = self.get_date(self.PS_file_path)
        if 'Dim' in PS_CSV_File_name:
            self.dataType = 'parameterSpace-Dim'
        elif 'Extend' in PS_CSV_File_name:
            self.dataType = 'parameterSpace-Extend'
        elif 'Geometry' in PS_CSV_File_name:
            self.dataType = 'parameterSpace-Geometry'
        elif 'New' in PS_CSV_File_name:
            self.dataType = 'parameterSpace-New'
        else:
            self.dataType = 'parameterSpace'
        self.schemaVersion = "1.1"
        self.parameters = self.get_paramter(self.PS_file)

    # Parameter space 파일의 path와 root를 얻음
    def get_PS_file(self, PS_dir, PS_CSV_File_name, folder_date):
        scenario_name = PS_CSV_File_name.split('_rawPS')[0]
        if len(PS_CSV_File_name.split('_rawPS')) > 1:
            raw_dataType = PS_CSV_File_name.split('_rawPS')[1]
        else:
            raw_dataType = 'Standard'
        PS_file_name = [file for file in os.listdir(PS_dir) if file.split('.')[0] == scenario_name][0]
        PS_file_path = os.path.join(PS_dir, PS_file_name, folder_date, PS_CSV_File_name+'.csv')
        PS_file = pd.read_csv(PS_file_path)

        return PS_file_path, PS_file, raw_dataType
########################################################

    def get_date(self, PS_file_path):
        # 파일이 존재하는지 확인
        if os.path.isfile(PS_file_path):
            # 파일의 수정 일자를 가져옴
            date = os.path.getmtime(PS_file_path)
            modified_date = datetime.fromtimestamp(date)
            formatted_date = modified_date.strftime("%Y-%m-%dT%H:%M:%S")


            return formatted_date
        else:
            return None  # 파일이 존재하지 않는 경우 None을 반환
    
    ##########################################################



    def get_paramter(self, PS_file):

        parameters = []

        parameter_format = {
            "name" : " ",
            "genParam" : {
                "range" : {
                    "max" : " ",
                    "min" : " "
                },
                "samplePoint" : " ",
                "value" : " "
            }
        }
            
        len_PS = PS_file.shape[1]
        
        for idx in range(len_PS) :
            tmp_parameter = copy.deepcopy(parameter_format)
            tmp_parameter['name'] = PS_file.iloc[:, idx].name
            tmp_parameter['genParam']['range']['min'] = float(PS_file.iloc[0,idx])
            tmp_parameter['genParam']['range']['max'] = float(PS_file.iloc[1,idx])
            
            parameters.append(tmp_parameter)

        return parameters
            
            
        
    
