"""
-----------------------------------
      Extract Campaign Data
-----------------------------------
"""

import pandas as pd

def extract_campaigns(file_path):
    return pd.read_csv(file_path)