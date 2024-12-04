'''
v0.2 can search with roadGeometry
'''

from pymongo import MongoClient
import os 
import seaborn as sns
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import pandas as pd
import datetime
from tqdm import tqdm

V_recog = {'FVL':0,'FVI':1,'FVR':2,'AVL':3,'AVR':4 , 'RVL':5,'RVI':6,'RVR':7}
V_maneu = {'LK' :0, 'LC':1}


class Detail_Query():
    def __init__(self,TYPE = "EXP-RG3", _my_query = None ):
        os.system('cls')        
        # print("HI 서도현 IM Detail query in Mongo DB ")

        # [Get time]
        now = datetime.datetime.now()
        self.now_str = now.strftime('%Y-%m-%d')

        # # [Connect client]
        self.db = self.connect_mongo_db()        
        self.Query = self.get_your_first_query(_my_query)
        self.Documents = self.get_document(self.Query)
        
        self.result_df = pd.DataFrame(columns=['frameIndex', 'recognition','maneuver', 'ObjectId'])
        self.df_index = 0

    def connect_mongo_db(self):
        '''
        input : None
        output : (METIS - SCENARIO) DB
        
        ex) db = Detail_Query().connect_mongo_db()
        '''
        client = MongoClient("mongodb://192.168.75.251:27017/")
        db = client['METIS']['Scenario']
        return db
    
    def get_your_first_query(self,_my_query = None):
        
        if _my_query == None: 
            my_query = input("plz put your Query...\n")
        else:
            my_query = _my_query
        return my_query
    
    def get_document(self, temp_query = None):
        Documents = list(self.db.find(temp_query))
        return Documents
    
    def query_in_documents(self, _document = []):
        Documents = _document
        frame_list = []
        for tmp_doc in tqdm(Documents):
            # init check
            init = tmp_doc['dynamic']['init']
            if np.size(init) > 1:
                self.check_target_in_init(tmp_doc, frame_list , init, 'FVL', 'LC')
                # frame_list += self.check_target_in_init(init, 'FVL', 'LC')
                
            # story check
            story = tmp_doc['dynamic']['story']['event']
            if np.size(story) > 1:
                self.check_target_in_story(tmp_doc, frame_list , story, 'FVL', 'LC')
                
                
                
                
                # frame_list += self.check_target_in_story(story, 'FVL', 'LC')
            
            # print(frame_list)
        
        # return frame_list

    def print_exported_dir(self, _document = []):
        Documents = _document
        for tmp_doc in Documents:
            print(tmp_doc['directory']['exported'])



    def check_target_in_init(self,tmp_doc, frame_list , init , recognition, maneuver):
        
        for tmp_init in init:
            if tmp_init['recognition'] == recognition and tmp_init['maneuver'] == maneuver:
                frame_list.append(tmp_init['frameIndex'])
                
                self.result_df.loc[self.df_index] = [tmp_init['frameIndex'], recognition , maneuver, tmp_doc['_id']]
                self.df_index += 1
    
    def check_target_in_story(self, tmp_doc, frame_list , story, recognition, maneuver):
        
        for tmp_story in story:
            if tmp_story['actors']['recognition'] == recognition and tmp_story['actors']['maneuver'] == maneuver:
                frame_list.append(tmp_story['frameIndex'])
                self.result_df.loc[self.df_index] = [tmp_story['frameIndex'], recognition , maneuver, tmp_doc['_id']]
                self.df_index += 1
                
    def get_participant(self, frame, objectid):
        doc = self.get_document({'_id':objectid})
        return doc

    def save_df2csv(self,save_name = 'result_df.csv'):
        '''
        input : save name
        output : csv file 
        
        ex) Detail_Query().save_df2csv(custom_name)
        '''
        self.result_df.to_csv(save_name, index=False, encoding='utf-8-sig')        
        
if __name__ == "__main__":
    Query =  {"$and":[{"dataType":"EXP-RG3"},{"directory.exported":{"$regex":"RG3_030223", "$options":"i"}},{"directory.registration":{"$regex":"RG3_030223", "$options":"i"}},{"directory.perception.SF":{"$regex":"RG3_030223", "$options":"i"}},{"dynamic.init.0":{"$exists":"true"}}]}
    # Query = {"dataType":"EXP-RG3"}
    
    DQ = Detail_Query(_my_query = Query)
    DQ.query_in_documents(DQ.Documents)
    DQ.save_df2csv(Query['$and'][1]['directory.exported']['$regex'])
    test = DQ.get_participant(1000, DQ.result_df['ObjectId'][0])
    print("DODODEONE")
    
    
    