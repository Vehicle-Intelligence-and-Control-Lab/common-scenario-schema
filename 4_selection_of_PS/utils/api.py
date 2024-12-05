#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys,os, signal
from utils.lib.controller import *
from utils.lib.launcher_start_api import *
from utils.lib.read_text import *
"""
https://docs.google.com/spreadsheets/d/1jHbR_JoZFYfxMirwSp-48peWkJf1xUmMZyFIwetxcZM/edit#gid=0

"""

class api :

    def __init__(self):         

        signal.signal(signal.SIGINT, self.signal_handler) #handle ctrl-c
        
        api = launcher_start()
        api.launcher_start()   

    def signal_handler(self, signal, frame):        
        sys.exit(0)                                           

if __name__ == "__main__":
    start=api()
    
