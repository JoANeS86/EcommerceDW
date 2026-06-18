"""
-----------------------------------------
     Web Events Spark Transformation
         Derived Date Attributes
-----------------------------------------
"""

from spark.scripts.spark_session import spark
from python.extract.json_web_events_simulator import generate_web_events

from pyspark.sql.functions import col, to_timestamp, to_date, year, month, dayofmonth

# --------------------------
# LOAD DATA
# --------------------------
raw_data = generate_web_events()
df = spark.createDataFrame(raw_data)

# --------------------------
# LIGHT CLEANING (repeat allowed here)
# --------------------------
df = df.dropna(subset=["event_id", "customer_id", "event_type", "event_timestamp"])

df = df.filter(col("event_type").isin(["page_view", "add_to_cart", "checkout"]))

df = df.dropDuplicates(["event_id"])

df = df.withColumn("event_timestamp", to_timestamp(col("event_timestamp")))
df = df.filter(col("event_timestamp").isNotNull())

# --------------------------
# TASK 4: DERIVED DATE FEATURES
# --------------------------
df = df.withColumn("event_date", to_date(col("event_timestamp")))
df = df.withColumn("event_year", year(col("event_timestamp")))
df = df.withColumn("event_month", month(col("event_timestamp")))
df = df.withColumn("event_day", dayofmonth(col("event_timestamp")))

# --------------------------
# OUTPUT
# --------------------------
df.show()
df.printSchema()