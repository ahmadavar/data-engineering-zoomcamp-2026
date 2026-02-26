from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = SparkSession.builder \
    .master("local[*]") \
    .appName("de-zoomcamp-module6") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

# Q1: Spark version
print("Q1 - Spark version:", spark.version)

# Load data
df = spark.read.parquet("data/yellow_tripdata_2025-11.parquet")

# Q2: Repartition to 4 and save
df.repartition(4).write.mode("overwrite").parquet("data/output/")

import os
sizes = [
    os.path.getsize(f"data/output/{f}") / (1024 * 1024)
    for f in os.listdir("data/output/")
    if f.endswith(".parquet")
]
print(f"Q2 - Parquet file sizes: {[round(s,1) for s in sizes]} MB")
print(f"Q2 - Average size: {round(sum(sizes)/len(sizes), 1)} MB")

# Q3: Trips on November 15
nov15 = df.filter(
    (F.to_date("tpep_pickup_datetime") == "2025-11-15")
).count()
print("Q3 - Trips on Nov 15:", nov15)

# Q4: Longest trip in hours
longest = df.withColumn(
    "duration_hours",
    (F.unix_timestamp("tpep_dropoff_datetime") - F.unix_timestamp("tpep_pickup_datetime")) / 3600
).agg(F.max("duration_hours")).collect()[0][0]
print(f"Q4 - Longest trip: {round(longest, 1)} hours")

# Q5: Spark UI port
print("Q5 - Spark UI port: 4040")

# Q6: Least frequent pickup zone
zones = spark.read.option("header", "true").csv("data/taxi_zone_lookup.csv")
least = df.groupBy("PULocationID").count() \
    .join(zones, df.PULocationID == zones.LocationID) \
    .orderBy("count") \
    .select("Zone", "count") \
    .first()
print(f"Q6 - Least frequent pickup zone: {least['Zone']} ({least['count']} trips)")

spark.stop()
