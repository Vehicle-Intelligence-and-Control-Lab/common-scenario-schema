import os
import pandas as pd
import numpy as np
import re





class XOSCGenerator:
    def __init__(self, logical_path, scenario_ps_path, save_output_dir, scenario_name):
        self.logical_path = logical_path
        self.scenario_ps_path = scenario_ps_path
        self.save_output_dir = save_output_dir
        self.scenario_name = scenario_name
        self.vehicle_spec = self.vehicle_specification()
        self.generate_scenario_files()

    def generate_scenario_files(self):
        print('----------------------------------------')
        print('Generate concrete scenario file...')
        
        # Load logical scenario file
        with open(self.logical_path, 'r', encoding='utf-8') as f:
            cur_scenario_info = f.read()
        cur_scenario_info_list = cur_scenario_info.splitlines()
        
        # Load PS file
        if not os.path.exists(self.scenario_ps_path):
            raise FileNotFoundError(f'No PS file found for {self.scenario_ps_path}')
        
        cur_ps_table = pd.read_csv(self.scenario_ps_path)
        
        # Extract information of entities
        cur_info_entities = self._extract_entity_info(cur_scenario_info_list)
        
        # Make test matrix
        test_matrix = self._generate_test_matrix(cur_ps_table, cur_scenario_info_list)
        
        # Modify parameters based on vehicle specification
        test_matrix = self._update_test_matrix_with_vehicle_spec(test_matrix, cur_info_entities)
        
        # Generate scenario files
        self._generate_concrete_scenario_files(test_matrix, cur_scenario_info_list, self.scenario_name, self.save_output_dir)

    def _extract_entity_info(self, scenario_info_list):
        # Extract <Entities> block
        entity_indices = [i for i, line in enumerate(scenario_info_list) if '<Entities' in line or '</Entities' in line]
        entity_block = scenario_info_list[entity_indices[0]:entity_indices[1] + 1]
        
        # Extract entity names
        entity_names = [line for line in entity_block if '<ScenarioObject' in line]
        vehicle_names = [line for line in entity_block if '<Vehicle' in line]
        
        entity_info = {
            'name': [self._parse_name(entity) for entity in entity_names],
            'entityName': [f'y{self._parse_name(vehicle)}' for vehicle in vehicle_names]
        }
        return entity_info

    def _parse_name(self, line):
        # Parse name from line in XML format
        return line.split('name="')[-1].split('"')[0]

    def _generate_test_matrix(self, ps_table, scenario_info_list):
        # Extract parameter declarations from scenario file
        param_decl_indices = [i for i, line in enumerate(scenario_info_list) if '<ParameterDeclarations' in line or '</ParameterDeclarations' in line]
        param_decls = scenario_info_list[param_decl_indices[0] + 1:param_decl_indices[1]]
        
        # Create a test matrix by combining parameters from the scenario file and PS table
        test_matrix = ps_table.copy()
        return test_matrix

    def _update_test_matrix_with_vehicle_spec(self, test_matrix, entity_info):
        # Adjust 'a_' parameters to absolute values
        for col in test_matrix.columns:
            if col.endswith('_Rate'):
                test_matrix[col] = np.abs(test_matrix[col])
        
        # Divide 'v_' parameters by 3.6
        for col in test_matrix.columns:
            if col.startswith('v_'):
                test_matrix[col] /= 3.6
        
        # Add extra vehicle length to 'dist_trigger' parameters
        if 'dist_trigger' in test_matrix.columns:
            for idx, entity in enumerate(entity_info['name']):
                vehicle_length = self.vehicle_spec.get(entity_info['entityName'][idx], {}).get('Length', 0)
                test_matrix['dist_trigger'] += vehicle_length
        
        return test_matrix

    def _generate_concrete_scenario_files(self, test_matrix, scenario_info_list, scenario_name, save_dir):
        if not os.path.exists(save_dir):
            os.makedirs(save_dir, exist_ok=True)
        
        for idx, row in test_matrix.iterrows():
            scenario_content = scenario_info_list.copy()
            for param_name in test_matrix.columns[1:]:
                param_value = row[param_name]
                for content_idx in range(len(scenario_content)):
                    if f'ParameterDeclaration name="{param_name}"' in scenario_content[content_idx]:
                        # "value" 부분을 찾아서 그 값을 param_value로 바꿉니다.
                        scenario_content[content_idx] = re.sub(r'value="[^"]*"', f'value="{param_value}"', scenario_content[content_idx])

            
            variation = row['Variation'].astype(int)
            file_name = f'{scenario_name}_{variation}.xosc'
            output_file_path = os.path.join(save_dir, file_name)
            with open(output_file_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(scenario_content))
            
            print(f'Generated scenario file for variation {variation} ({idx + 1}/{len(test_matrix)})')

    def vehicle_specification(self):
        y2016_Hyundai_Genesis_DH = {
            'Length': 4.9960,
            'Width': 1.9200,
            'Front_Overhang': 0.8460,
            'Rear_Overhang': 1.1400
        }
        y2021_Volkswagen_Golf_GTI = {
            'Length': 4.3800,
            'Width': 1.7800,
            'Front_Overhang': 0.8600,
            'Rear_Overhang': 0.8890
        }
        y2014_Kia_K7 = {
            'Length': 5.0100,
            'Width': 1.8850,
            'Front_Overhang': 1,
            'Rear_Overhang': 1.1200
        }
        y2015_Kia_K5 = {
            'Length': 4.8450,
            'Width': 1.8350,
            'Front_Overhang': 0.9650,
            'Rear_Overhang': 1.0850
        }
        y2020_Kia_stinger = {
            'Length': 4.8300,
            'Width': 1.8700,
            'Front_Overhang': 0.8300,
            'Rear_Overhang': 1.0950
        }
        y2016_Hyundai_Ioniq = {
            'Length': 4.4700,
            'Width': 1.8200,
            'Front_Overhang': 0.8800,
            'Rear_Overhang': 0.8900
        }
        vehicle_spec = {
            'y2016_Hyundai_Genesis_DH': y2016_Hyundai_Genesis_DH,
            'y2021_Volkswagen_Golf_GTI': y2021_Volkswagen_Golf_GTI,
            'y2014_Kia_K7': y2014_Kia_K7,
            'y2015_Kia_K5': y2015_Kia_K5,
            'y2020_Kia_stinger': y2020_Kia_stinger,
            'y2016_Hyundai_Ioniq': y2016_Hyundai_Ioniq
        }
        return vehicle_spec

