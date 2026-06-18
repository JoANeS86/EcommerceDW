"""
-----------------------------------------
    Web Events Spark Aggregations
-----------------------------------------
"""

from spark.scripts.spark_session import spark
from python.extract.json_web_events_simulator import generate_web_events

from pyspark.sql.functions import col, to_timestamp, to_date, year, month, dayofmonth, count

# -------------------------------------------------
# LOAD DATA
# -------------------------------------------------
raw_data = generate_web_events()
df = spark.createDataFrame(raw_data)

# -------------------------------------------------
# BASIC CLEANING (reused logic)
# -------------------------------------------------
df = df.dropna(subset=["event_id", "customer_id", "event_type", "event_timestamp"])

df = df.filter(col("event_type").isin(["page_view", "add_to_cart", "checkout"]))

df = df.dropDuplicates(["event_id"])

df = df.withColumn("event_timestamp", to_timestamp(col("event_timestamp")))
df = df.filter(col("event_timestamp").isNotNull())

# -------------------------------------------------
# DERIVED DATE ATTRIBUTES (needed for aggregations)
# -------------------------------------------------
df = df.withColumn("event_date", to_date(col("event_timestamp")))
df = df.withColumn("event_year", year(col("event_timestamp")))
df = df.withColumn("event_month", month(col("event_timestamp")))

# -------------------------------------------------
# TASK 5: AGGREGATIONS
# -------------------------------------------------

# 1. Events per day
events_per_day = df.groupBy("event_date").agg(
    count("*").alias("count_events")
)

# 2. Events per month
events_per_month = df.groupBy("event_month").agg(
    count("*").alias("count_events")
)

# 3. Events per event type
events_per_type = df.groupBy("event_type").agg(
    count("*").alias("count_events")
)

# -------------------------------------------------
# OUTPUT
# -------------------------------------------------
print("=== EVENTS PER DAY ===")
events_per_day.show()

print("=== EVENTS PER MONTH ===")
events_per_month.show()

print("=== EVENTS PER TYPE ===")
events_per_type.show()