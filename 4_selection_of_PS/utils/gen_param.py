import pandas as pd
import numpy as np
import itertools

class GenParam():
    def __init__(self, ranges, sample_size, method):
        self.ranges = ranges
        self.sample_size = sample_size
        self.method = method
        self.param_table = self.parameter_generator()

    def parameter_generator(self):
        # 파라미터 이름과 범위 추출
        parameters = self.ranges.columns
        self.ranges = self.ranges.values.T  # numpy 배열로 변환 (transpose)

        # 파라미터 차원 수 결정
        param_dimension = len(parameters)
        parameter_values = []

        for idx in range(param_dimension):
            cur_min = self.ranges[idx, 0]
            cur_max = self.ranges[idx, 1]

            if self.method == 'linear':
                # 선형 간격 방식으로 파라미터 값 생성
                cur_parameter_values = np.linspace(cur_min, cur_max, self.sample_size)

            parameter_values.append(cur_parameter_values)

        # 파라미터의 모든 조합 생성
        param_array = self.combinations(*parameter_values)

        # 파라미터 이름으로 DataFrame 생성 
        param_table = pd.DataFrame(param_array, columns=parameters)
        param_table['Variation'] = np.arange(param_array.shape[0])
        cols = ['Variation'] + [col for col in param_table.columns if col != 'Variation']
        param_table = param_table[cols]
        return param_table

    @staticmethod
    def combinations(*arrays):
        # 각 배열의 카르테시안 곱을 생성하여 모든 조합 반환
        product = itertools.product(*arrays)
        return np.array(list(product))
