import json

def Read_config(Config_dir):    
    with open(Config_dir) as f:
        Config = json.load(f)
    return Config

def Vehicle_type_check(_dir):
    if "RG3" in _dir:
        return "RG3"
    elif "CN7" in _dir:
        return "CN7"
    else: 
        print("Error")
        return None
    
def get_vehicle_dict(vehicle,RG3,CN7):
    if vehicle == "RG3":
        return RG3
    elif vehicle == "CN7":
        return CN7
    else: 
        print("Error")
        return None

