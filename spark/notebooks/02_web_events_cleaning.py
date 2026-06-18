"""
-----------------------------------
   Spark Data Validation Layer
-----------------------------------
"""

from spark.scripts.spark_session import spark
from python.extract.json_web_events_simulator import generate_web_events

from pyspark.sql.functions import col, to_timestamp

# -------------------------------------------------
# CONFIG
# -------------------------------------------------
VALID_EVENT_TYPES = ["page_view", "add_to_cart", "checkout"]

# -------------------------------------------------
# 1. GENERATE RAW DATA (synthetic source)
# -------------------------------------------------
raw_data = generate_web_events()

# Convert directly into Spark DataFrame
df = spark.createDataFrame(raw_data)

# -------------------------------------------------
# 2. DATA CLEANING (SPARK VERSION)
# -------------------------------------------------

# 2.1 Drop critical nulls
df = df.dropna(subset=[
    "event_id",
    "customer_id",
    "event_type",
    "event_timestamp"
])

# 2.2 Keep only valid event types
df = df.filter(
    col("event_type").isin(VALID_EVENT_TYPES)
)

# 2.3 Remove duplicates (based on event_id)
df = df.dropDuplicates(["event_id"])

# 2.4 Convert timestamp + remove invalid dates
df = df.withColumn(
    "event_timestamp",
    to_timestamp(col("event_timestamp"))
)

df = df.filter(
    col("event_timestamp").isNotNull()
)

# -------------------------------------------------
# 3. VALIDATION OUTPUT
# -------------------------------------------------
df.show()
df.printSchema()
print("Final row count:", df.count())