# Module 6: Batch Processing with Spark

## Overview

This module covers batch processing using Apache Spark and PySpark — distributed computing for processing large datasets at scale.

## Setup

```bash
sudo apt install -y openjdk-17-jre-headless
pip install pyspark
```

**Versions:** Java 17, PySpark 4.1.1

## Dataset

- Yellow Taxi November 2025 (~4M rows, Parquet)
- Taxi Zone Lookup CSV

## What I Did

- Created a local Spark session with `local[*]` (all cores)
- Read Parquet file into a Spark DataFrame
- Repartitioned to 4 partitions and wrote back to Parquet
- Filtered trips by date using `tpep_pickup_datetime`
- Calculated trip duration in hours using `unix_timestamp`
- Joined trips with zone lookup to find least frequent pickup zone
- Used Spark UI (port 4040) to monitor job execution

## Running

```bash
cd 06-batch-spark
python3 homework.py
```

## Homework Answers

| Q | Answer |
|---|--------|
| Q1 - Spark version | `4.1.1` |
| Q2 - Avg parquet file size | `25 MB` |
| Q3 - Trips on Nov 15 | `162,604` |
| Q4 - Longest trip | `90.6 hours` |
| Q5 - Spark UI port | `4040` |
| Q6 - Least frequent pickup zone | `Governor's Island/Ellis Island/Liberty Island` |

## Key Learnings

- Spark processes data in partitions across workers — `repartition(4)` controls parallelism
- `local[*]` uses all available CPU cores for local mode
- Parquet is Spark's native format — reads/writes are highly optimized
- `unix_timestamp` difference divided by 3600 gives duration in hours
- Spark UI on port 4040 shows stages, tasks, DAG, and execution metrics
- Joins in Spark are distributed — zone lookup was broadcast automatically
