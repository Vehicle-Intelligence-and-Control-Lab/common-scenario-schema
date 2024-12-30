# Common-Scenario-Schema

The scenario-based approach is used for generation of safety-critical scenarios. It is applied for various applications ranging from development of perception and decision algorithms to the corresponding test and validation.

## Table of Contents

- [Docs](#docs)
- [Installation](#installation)
- [Usage](#usage)

## Installation

Installing Packages

```Python
pip install -r requirements.txt
```

## Usage

### 1. CSS for logical scenario (Code)

After the logical scenarios are created or programmed in the framework of CarMaker or MORAI SIM (i.e., XOSC), create a common scenario schema (CSS) corresponding to the scenario database. 
The schema code for databasing logical scenarios created with MORAI is ```css_for_xosc.py```.

```Python
##################### Setting ##########################

# 생성할 Logical scenario catalog
TESTBED = 0
SOTIF_1st = 0
SOTIF_2nd = 1
SOTIF_3rd = 0

# Logical scenario 생성 토글
single_toggle = 1              # 1:ON  0:OFF
i = 12                           # 생성할 Logical scenario 번호 (single toggle에 해당, 가장 아래 번호 리스트 확인 가능)

multiple_toggle =0             # 1:ON  0:OFF

# 파일 경로
registration_dir = r"\\192.168.75.251\Shares\MORAI Scenario Data\SOTIF Catalogue\MORAI Project\Registration"
save_dir = r"\\192.168.75.251\Shares\MORAI Scenario Data\SOTIF Catalogue\MORAI Project\Json"

########################################################
```

### 2. Generation of raw parameter space (Manual)

- rawPS: Parameter ranges defined by expert knowledge
- rawPS_Dim: Adding the parameter dimension of an existing scenario
- rawPS_Extend: Extending parameter ranges for existing scenarios
- rawPS_Geometry: Changing road terrain in an existing scenario
- rawPS_New: Defining scenario parameters at the wrong point in time for a non-existent algorithm in an existing scenario catalog






