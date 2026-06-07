"""
-----------------------------------
    Web Events Spark Dataframe
-----------------------------------
"""

import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from spark.scripts.spark_session import spark
from python.extract.json_web_events_simulator import generate_web_events
from python.transform.clean_web_events import clean_web_events
from datetime import datetime

# generate events
raw_data = generate_web_events()

# clean events (optional, depending if you want Spark to see raw or cleaned)
import pandas as pd
df_cleaned = clean_web_events(raw_data, logger=None)  # returns pandas DataFrame

# convert pandas DataFrame to Spark DataFrame
df_spark = spark.createDataFrame(df_cleaned)

# explore
df_spark.show()
df_spark.printSchema()
print("Total rows:", df_spark.count())