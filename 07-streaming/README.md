# Module 7: Stream Processing with PyFlink

## Overview

This module covers real-time stream processing using Apache Flink (PyFlink) with Redpanda as a Kafka-compatible message broker.

## Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Message Broker | Redpanda v24.2.18 | Kafka-compatible streaming platform |
| Stream Processor | Apache Flink 1.16 (PyFlink) | Stateful stream processing |
| Sink | PostgreSQL 14 | Landing zone for processed results |
| Producer | kafka-python | Sending taxi data to topics |

## Setup

```bash
cd 07-streaming/pyflink
docker compose build   # builds pyflink:1.16.0 image (~5-10 min)
docker compose up -d   # starts redpanda, jobmanager, taskmanager, postgres
```

**Containers:**
- `redpanda-1` — Kafka-compatible broker (port 9092)
- `flink-jobmanager` — Flink UI at http://localhost:8081
- `flink-taskmanager` — Executes Flink tasks
- `postgres` — Result storage (port 5432)

## Dataset

Green Taxi October 2019 — 476,386 trips

```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2019-10.parquet -O pyflink/data/green_tripdata_2019-10.parquet
wget https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv -O pyflink/data/taxi_zone_lookup.csv
```

## What I Did

- Spun up Redpanda + Flink + Postgres with Docker Compose
- Created `green-trips` Kafka topic using `rpk` CLI
- Built a Kafka producer to send 476K taxi trips as JSON messages
- Built a PyFlink session window job consuming from `green-trips`
- Computed session windows (5-min gap, watermark on dropoff time)
- Identified the PU/DO pair with the longest unbroken streak

## Running

```bash
# Send data to Kafka
python3 pyflink/src/producer.py

# Submit Flink session job
docker cp pyflink/src/session_job.py flink-jobmanager:/opt/flink/usrlib/session_job.py
docker exec flink-jobmanager flink run -py /opt/flink/usrlib/session_job.py

# Compute session answer
python3 pyflink/src/q5_session.py
```

## Homework Answers

| Q | Answer |
|---|--------|
| Q1 - Redpanda version | `v24.2.18` |
| Q2 - Create topic output | `green-trips OK` |
| Q3 - Kafka connection | `True` |
| Q4 - Time to send 476K messages | ~194 seconds |
| Q5 - Longest session streak (2pts) | East Harlem South → East Harlem North (1,680 trips) |

## Key Learnings

- Redpanda is a drop-in Kafka replacement — same API, faster startup, no JVM dependency
- Flink session windows group events where no gap exceeds the threshold (5 min here)
- Watermarks handle late-arriving events — 5-second tolerance means events up to 5s late are still processed
- With historical (bounded) data, Flink watermarks may not advance past the last event — session windows won't flush unless a future event is received
- `rpk` is Redpanda's CLI tool for topic management, cluster info, and version checks
- Flink UI (port 8081) shows running jobs, stages, and task manager status
