import numpy as np
import pandas as pd

class SampleParam():
    def __init__(self, param_table, num_of_samples):
        self.param_table = param_table
        self.num_of_samples = num_of_samples
        self.sampled_param_table = self.sample_param()
    
    def sample_param(self):
        parameter_variables_length = len(self.param_table.iloc[:, 0])
        num_to_pick = self.num_of_samples

        # 총 시나리오 중에서 랜덤으로 선택된 행의 인덱스
        random_indices = np.random.choice(parameter_variables_length, num_to_pick, replace=False)

        # 선택된 행들로 새로운 데이터프레임 생성
        sampled_param_table = self.param_table.iloc[random_indices]

        # 'Variation' 열 기준으로 오름차순 정렬
        sampled_param_table = sampled_param_table.sort_values(by='Variation', ascending=True)

        return sampled_param_table