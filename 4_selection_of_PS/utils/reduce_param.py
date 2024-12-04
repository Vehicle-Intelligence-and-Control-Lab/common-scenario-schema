import pandas as pd
import numpy as np
import itertools


class ReduceParam():
    def __init__(self, param_table, cur_scenario, toggle_SVM):
        """
        self.toggle_SVM : SVM을 사용할지 여부 (0: 사용하지 않음, 1: 사용)
        """
        self.param_table = param_table
        self.cur_scenario = cur_scenario
        if toggle_SVM == 'SVM':
            self.toggle_SVM = 1
        else:
            self.toggle_SVM = 0
        self.reduced_param_table = self.reduce_param()


    def reduce_param(self):
        """
        매개변수 공간을 줄이는 함수
        cur_scenario : 현재 시나리오 선택
        return : 축소된 매개변수 테이블
        """
        parameter_variables_length = len(self.param_table.columns)
        parameter_declaration = self.param_table.columns

        # param_table의 열(column) 이름을 이용해 index 딕셔너리 초기화
        index = {col_name: idx for idx, col_name in enumerate(self.param_table.columns)}
        total_df = pd.DataFrame(index=range(len(self.param_table)), columns=parameter_declaration)

        critical_scenarios = [
            'LK_PCSL_STP_ST', 'LK_PCSR_STP_ST', 'LK_CCSL_ST', 'LK_CCSR_ST',
            'LT_POC_IN', 'LK_CGSL2R_IN', 'LK_CGSR2L_IN', 'LT_CCSL_IN', 'LT_CCSR_IN',
            'LT_CGSR2L_IN', 'LT_COC_IN', 'RT_CCSL_IN', 'RT_CCSR_IN', 'RT_CGSL2R_IN',
            'RT_CGSR2L_IN', 'LK_ECSL_ST', 'LK_ECSL_STP_ST', 'LK_EGSL2R_IN', 
            'LK_EGSR2L_IN', 'LT_ECSL_IN', 'LT_EGSR2L_IN', 'LT_EOC_IN', 'RT_ECSR_IN',
            'RT_EGSL2R_IN'
        ]

        if self.cur_scenario in critical_scenarios:
            # 차량 크기 및 초기 측면 상대 거리 설정
            if self.cur_scenario in ['LK_PCSL_ST', 'LK_PCSR_ST', 'LK_PCSL_STP_ST', 'LK_PCSR_STP_ST', 'LK_CCSL_ST', 'LK_CCSR_ST']:
                LENGTH_EGO = 4.996
                WIDTH_EGO = 1.92
                INIT_LAT_REL_DIST = 6 - WIDTH_EGO / 2
            elif self.cur_scenario == 'LT_POC_IN':
                LENGTH_EGO = 4.236
                WIDTH_EGO = 1.6
                INIT_LAT_REL_DIST = 23 - WIDTH_EGO / 2
            elif self.cur_scenario in ['LK_CGSL2R_IN', 'LK_EGSL2R_IN']:
                LENGTH_EGO = 4.236
                WIDTH_EGO = 1.6
                INIT_LAT_REL_DIST = 30 - WIDTH_EGO / 2
            else:
                LENGTH_EGO = 4.236
                WIDTH_EGO = 1.6
                INIT_LAT_REL_DIST = 20 - WIDTH_EGO / 2

            # 매개변수 변환 및 계산
            v_ego = self.param_table['v_ego'] / 3.6
            v_target = self.param_table['v_target'] / 3.6
            dist_trigger = self.param_table['dist_trigger'] / (self.param_table['v_ego'] - self.param_table['v_target'])
            
            in_lane_time = INIT_LAT_REL_DIST / v_target
            in_lane_time_long_rel_dist = dist_trigger - v_ego * in_lane_time
            in_lane_time_TTC = in_lane_time_long_rel_dist / v_ego

            # Constraint - Longitudinal constraint에 맞는 데이터 필터링
            filtered_df = self.param_table[in_lane_time_long_rel_dist > -LENGTH_EGO]
        
            return filtered_df
        
        elif self.cur_scenario == 'RT_CSD_IN':
            # 단위 변환 (km/h -> m/s)
            v_ego = self.param_table['v_ego'] / 3.6
            v_target = self.param_table['v_target'] / 3.6
            dist_trigger = self.param_table['dist_trigger']

            # total_df에 필요한 열에 데이터 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['offset_ego'] = self.param_table['offset_ego']
            total_df['dist_trigger'] = self.param_table['dist_trigger']

            # 시간 계산
            time_target_arrive_IN = 20 / v_target
            time_ego_arrive_IN = (20 + dist_trigger) / v_ego

            # 조건에 맞는 행 필터링
            condition = (time_ego_arrive_IN - time_target_arrive_IN > 2) | \
                        (time_ego_arrive_IN - time_target_arrive_IN > -1)
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario in ['LK_LF_ST', 'LK_LF_SH']:
            # 추가 인덱스 설정
            index['TTC_Trigger'] = parameter_variables_length + 1

            # 필요한 매개변수 설정
            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            R_decelleration = self.param_table['R_dec']
            rel_velocity = (ego_velocity - target_velocity) / 3.6
            TTC_trigger = R_decelleration / rel_velocity

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['a_target'] = self.param_table['a_target']
            total_df['R_dec'] = self.param_table['R_dec']
            total_df['TTC_Trigger'] = TTC_trigger

            # ego_velocity > target_velocity 조건에 맞는 데이터 필터링
            condition = ego_velocity > target_velocity
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario in ['LK_CIL_ST', 'LK_CIR_ST', 'LK_CIL_CU', 'LK_CIL_SH', 'LK_CIR_CU']:
            index['TTC_Trigger'] = parameter_variables_length + 1
            index['t_cut_in_max'] = parameter_variables_length + 2

            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            R_cut_in = self.param_table['R_cut_in']
            rel_velocity = (ego_velocity - target_velocity) / 3.6
            TTC_trigger = R_cut_in / rel_velocity

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['t_cut_in'] = self.param_table['t_cut_in']
            total_df['R_cut_in'] = self.param_table['R_cut_in']
            total_df['TTC_Trigger'] = TTC_trigger

            # ego_velocity > target_velocity 조건에 맞는 데이터 필터링
            condition = ego_velocity > target_velocity
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario in ['LK_COL_STP_ST', 'LK_COR_STP_ST', 'LK_COR_STP_CU']:
            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            dist_trigger = self.param_table['R_cut_out']
            rel_velocity = (ego_velocity - target_velocity) / 3.6

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['t_cut_out'] = self.param_table['t_cut_out']
            total_df['R_cut_out'] = self.param_table['R_cut_out']

            # ego_velocity == target_velocity 조건에 맞는 데이터 필터링
            condition = ego_velocity == target_velocity
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario == 'overReliance':
            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            dist_trigger = self.param_table['R_cut_out']
            rel_velocity = (ego_velocity - target_velocity) / 3.6

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['v_target2'] = self.param_table['v_target2']
            total_df['a_target1'] = self.param_table['a_target1']
            total_df['t_cut_out'] = self.param_table['t_cut_out']
            total_df['R_cut_out'] = self.param_table['R_cut_out']
            total_df['R_dec'] = self.param_table['R_dec']

            # ego_velocity == target_velocity 조건에 맞는 데이터 필터링
            condition = ego_velocity == target_velocity
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario == 'LK_LF_LF_ST':
            ego_velocity = self.param_table['v_ego']
            ego_initial_s = self.param_table['ego_start']
            target1_initial_s = self.param_table['target1_start']
            target2_initial_s = self.param_table['target2_start']
            dis1 = abs(target1_initial_s - ego_initial_s)
            dis2 = abs(ego_initial_s - target2_initial_s)

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['ego_start'] = self.param_table['ego_start']
            total_df['target1_start'] = self.param_table['target1_start']
            total_df['target2_start'] = self.param_table['target2_start']
            total_df['a_target'] = self.param_table['a_target']

            # dis1 == dis2 조건에 맞는 데이터 필터링
            condition = dis1 == dis2
            filtered_df = total_df[condition]

            return filtered_df

        elif self.cur_scenario in ['drivingAlone']:

            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['t_cut_in'] = self.param_table['t_cut_in']
            total_df['R_cut_in'] = self.param_table['R_cut_in']

            # 조건에 맞는 데이터 필터링
            condition_1 = (self.param_table['v_ego'] < self.param_table['v_target']) & \
                        (36 < abs(self.param_table['v_ego'] - self.param_table['v_target'])) & \
                        (abs(self.param_table['v_ego'] - self.param_table['v_target']) < 108)

            condition_2 = (self.param_table['v_ego'] < self.param_table['v_target']) & \
                        (30 <= abs(self.param_table['v_ego'] - self.param_table['v_target'])) & \
                        (abs(self.param_table['v_ego'] - self.param_table['v_target']) < 40) & \
                        (self.param_table['R_cut_in'] > 5) & (self.param_table['t_cut_in'] < 1.5)

            # 조건에 맞는 행 필터링
            filtered_df = total_df[condition_1 | condition_2]

            return filtered_df

        elif self.cur_scenario == 'Cut_in_FP' or self.cur_scenario == 'Cut_In_Lateral':
            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            rel_velocity = ego_velocity - target_velocity
            a_target = self.param_table['a_target']
            R_cut_in = self.param_table['R_cut_in']

            # total_df에 필요한 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['R_cut_in'] = self.param_table['R_cut_in']
            total_df['t_cut_in'] = self.param_table['t_cut_in']
            total_df['y_cut_in'] = self.param_table['y_cut_in']
            total_df['a_target'] = self.param_table['a_target']

            # 첫 번째 조건: ego_velocity > target_velocity 및 rel_velocity < 50
            condition_1 = (ego_velocity > target_velocity) & (rel_velocity < 50)
            total_df_const_1 = total_df[condition_1]

            # 두 번째 조건: a_target > -3 또는 target_velocity > 20
            condition_2 = (a_target > -3) | (target_velocity > 20)
            total_df_const_2 = total_df[condition_2]

            # 두 조건을 모두 만족하는 행 필터링
            filtered_df = pd.merge(total_df_const_1, total_df_const_2)

            return filtered_df
        
        elif self.cur_scenario in ['LCL_LF_ST', 'LCR_LF_ST']:
            ego_velocity = self.param_table['v_ego']
            target_velocity = self.param_table['v_target']
            rel_velocity = ego_velocity - target_velocity

            # total_df에 값 할당
            total_df['Variation'] = self.param_table['Variation']
            total_df['v_ego'] = self.param_table['v_ego']
            total_df['v_target'] = self.param_table['v_target']
            total_df['t_cut_in'] = self.param_table['t_cut_in']
            total_df['R_cut_in'] = self.param_table['R_cut_in']

            # Longitudinal constraint 적용: ego_velocity < target_velocity 조건에 맞는 데이터 필터링
            condition = ego_velocity < target_velocity
            filtered_df = total_df[condition]
            
            return filtered_df
        
        else:
            return None

