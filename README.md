# Common-Scenario-Schema

The scenario-based approach is used for generation of safety-critical scenarios. It is applied for various applications ranging from development of perception and decision algorithms to the corresponding test and validation.

![스크린샷 2024-12-31 131746](https://github.com/user-attachments/assets/35d85d97-4b5c-4cd4-a151-8580e08f5192)

## Table of Contents

- [Docs](#docs)
- [Installation](#installation)
- [Usage](#usage)

## Installation

Installing Packages

- scipy >= 1.14.0
- h5py >= 3.12.1
- pandas >= 2.2.2
- colorama >= 0.4.6
- tqdm >= 4.66.4
- natsort >= 8.4.0
- openpyxl >= 3.1.5
- pymongo >= 4.8.0

```Python
pip install -r requirements.txt
```

## Usage

### A. S2/S3
![image (12)](https://github.com/user-attachments/assets/93f01dcf-969f-4a4f-ac1b-01f9b1e6285b)


#### A.1. Generation of logical scenario (Manual)
Logical scenarios are defined as knowledge-based, data-driven (FOT), and scenario augmentation processes. To implement the defined logical scenarios in a file, you must create a file for your simulator.

Logical scenario file extensions to create
- xosc (MORAI) 
- testrun (carmaker)


#### A.2. CSS for logical scenario (Code)
After the logical scenarios are created or programmed in the framework of CarMaker or MORAI SIM (i.e., XOSC), create a common scenario schema (CSS) corresponding to the scenario database. 
The schema code for databasing logical scenarios created with MORAI is ```css_for_xosc.py```.
The output of the code is a JSON file.

```Python
##################### Setting ##########################

# Logical scenario catalog
TESTBED = 0
SOTIF_1st = 0
SOTIF_2nd = 1
SOTIF_3rd = 0

# Logical scenario toggle
single_toggle = 1              # 1:ON  0:OFF
i = 12                           # 생성할 Logical scenario 번호 (single toggle에 해당, 가장 아래 번호 리스트 확인 가능)

multiple_toggle =0             # 1:ON  0:OFF

# File path
registration_dir = r"\\192.168.75.251\Shares\MORAI Scenario Data\Scenario Catalog for SOTIF\MORAI Project\Registration"
save_dir = r"\\192.168.75.251\Shares\MORAI Scenario Data\Scenario Catalog for SOTIF\MORAI Project\Json"

########################################################
```

#### A.3. Generation of raw parameter space (Manual)
raw parameter space file name to create
- rawPS: Parameter ranges defined by expert knowledge
- rawPS_Dim: Adding the parameter dimension of an existing scenario
- rawPS_Extend: Extending parameter ranges for existing scenarios
- rawPS_Geometry: Changing road terrain in an existing scenario
- rawPS_New: Defining scenario parameters at the wrong point in time for a non-existent algorithm in an existing scenario catalog


#### A.4. CSS for raw parameter space (Code)
Create a schema for database with the generated raw parameter space.
The code for generating the schema is ```css_for_RawPS.py```.
The output of the code is a JSON file.

#### A.5. CSS for road (Code)
This is the code that populates the schema with road information relevant to the scenario generation. 
The code for adding this information is ```css_for_road.py```.
The output of the code is a JSON file.

### B. S3/S4/S5
![image (14)](https://github.com/user-attachments/assets/8f9190d4-5761-489e-80b2-3764e335c660)


#### B.1. Selection of parameter space & test automation (Code)
This section explores the logical scenarios stored in the database to create detailed scenarios and automate simulations according to the single parameter distribution method defined by OpenSCENARIO. 

The simulator consists of MORAI SIM and CarMaker, and in the case of MORAI SIM, a detailed scenario is created in the form of xosc and the simulation is executed, and in the case of CarMaker, a parameter space(.csv) is created and used as an input for the simulation. 

we first create detailed scenarios and output the csv file and xosc file. Then, the detailed scenarios are executed in each simulator to output the simulation result file and GT file.

output
- carmaker : sim result(.mat), GT(.mat)














