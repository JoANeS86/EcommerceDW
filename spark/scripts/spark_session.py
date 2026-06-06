"""
-----------------------------------
          Spark Session
-----------------------------------
"""

# Create a Spark session to use Spark in the Python script.

from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("EcommerceDW")
    .getOrCreate()
)

print(spark.version)