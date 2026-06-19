"""
-----------------------------------------
      Web Events Spark SQL
-----------------------------------------
"""

from spark.scripts.spark_session import spark
from python.extract.json_web_events_simulator import generate_web_events

from pyspark.sql.functions import (
    col,
    to_timestamp,
    count
)

# -------------------------------------------------
# LOAD DATA
# -------------------------------------------------
raw_data = generate_web_events()
df = spark.createDataFrame(raw_data)

# -------------------------------------------------
# BASIC CLEANING
# -------------------------------------------------
df = df.dropna(
    subset=[
        "event_id",
        "customer_id",
        "event_type",
        "event_timestamp"
    ]
)

df = df.filter(
    col("event_type").isin(
        ["page_view", "add_to_cart", "checkout"]
    )
)

df = df.dropDuplicates(["event_id"])

df = df.withColumn(
    "event_timestamp",
    to_timestamp(col("event_timestamp"))
)

df = df.filter(
    col("event_timestamp").isNotNull()
)

# -------------------------------------------------
# CREATE TEMP VIEW
# -------------------------------------------------
df.createOrReplaceTempView("web_events")

# -------------------------------------------------
# SPARK SQL
# -------------------------------------------------
sql_result = spark.sql("""
SELECT
    event_type,
    COUNT(*) AS count_events
FROM web_events
GROUP BY event_type
ORDER BY count_events DESC
""")

# -------------------------------------------------
# DATAFRAME API EQUIVALENT
# -------------------------------------------------
api_result = (
    df.groupBy("event_type")
      .agg(count("*").alias("count_events"))
      .orderBy(col("count_events").desc())
)

# -------------------------------------------------
# OUTPUT
# -------------------------------------------------
print("\n=== SPARK SQL RESULT ===")
sql_result.show()

print("\n=== DATAFRAME API RESULT ===")
api_result.show()