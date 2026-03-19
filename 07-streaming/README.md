# Module 7: Stream Processing with Kafka + PyFlink

## Overview

This module covers real-time stream processing using a two-layer streaming architecture:

- **Kafka (Redpanda)** — the message broker / transport layer. Receives, stores, and delivers messages via topics.
- **PyFlink (Apache Flink)** — the stream processor / computation layer. Reads from Kafka, applies tumbling/session windows, and writes results to Postgres.

Redpanda is a drop-in Kafka replacement (same API, no JVM). Everything works identically with a real Kafka cluster.

```
Producer (kafka-python)
        │  publishes JSON messages
        ▼
  Redpanda / Kafka              ← Message Broker
  [green-trips topic]
        │  streams events
        ▼
  PyFlink Window Jobs           ← Stream Processor
        │  writes aggregated results
        ▼
     PostgreSQL                 ← Sink
```

### Kitchen Analogy

| Component | Analogy |
|-----------|---------|
| Kafka | The order ticket rail above a restaurant pass — holds every order, nothing gets lost, anyone can read it |
| Flink | The head chef — reads tickets off the rail, does the computation, writes the result |
| Postgres | The final bill / results sheet |

You need both because Kafka absorbs the firehose of events reliably, while Flink does the actual thinking (windows, counts, sums). Neither does the other's job.

---

## Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Message Broker | Kafka / Redpanda v25.3.9 | Durable topic-based message transport |
| Stream Processor | Apache Flink 2.2.0 (PyFlink) | Stateful stream processing & windowing |
| Sink | PostgreSQL 18 | Landing zone for processed results |
| Producer | kafka-python | Publishing taxi trip events to Kafka topic |

---

## Setup

```bash
cd 07-streaming/workshop
docker compose build   # builds pyflink-workshop image (~5-10 min)
docker compose up -d   # starts redpanda, jobmanager, taskmanager, postgres
```

> **Note:** If port 5432 is occupied (e.g. another Postgres container), change the host port in `docker-compose.yml`:
> ```yaml
> ports:
>   - "5434:5432"   # use any free port on the left side
> ```

**Containers:**
- `workshop-redpanda-1` — Kafka-compatible broker (port 9092)
- `workshop-jobmanager-1` — Flink UI at http://localhost:8081
- `workshop-taskmanager-1` — Executes Flink tasks
- `workshop-postgres-1` — Result storage (port 5432 inside, mapped as needed)

---

## Dataset

Green Taxi **October 2025** — 49,416 trips

```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet \
  -O workshop/green_tripdata_2025-10.parquet
```

---

## How We Solved Each Question

### Q1 — Redpanda Version

```bash
docker exec workshop-redpanda-1 rpk version
```

`rpk` is Redpanda's CLI tool (like `kafka-topics.sh` for Kafka). It can check version, create topics, produce/consume messages.

---

### Q2 — Time to Send Data to Kafka

First create the topic:

```bash
docker exec workshop-redpanda-1 rpk topic create green-trips
```

Then run the producer (`src/producers/hw_producer.py`):

```bash
python3 src/producers/hw_producer.py
```

**Key gotcha — NaN values:** The parquet file has `NaN` in `passenger_count`. Python's pandas can hold NaN internally, but JSON has no NaN token. Flink's JSON deserializer crashes on it. Fix: replace NaN with `None` before serializing so it becomes JSON `null`:

```python
record = {k: (None if pd.isna(v) else v) for k, v in row.to_dict().items()}
```

---

### Q3 — Consumer: Count Trips with trip_distance > 5

Run the consumer (`src/consumers/hw_consumer.py`):

```bash
python3 src/consumers/hw_consumer.py
```

The consumer sets `auto_offset_reset='earliest'` so it reads from the very beginning of the topic, counts all messages, and filters on `trip_distance > 5.0`.

---

### Q4, Q5, Q6 — PyFlink Jobs

Before running jobs, create the result tables in Postgres:

```bash
docker exec workshop-postgres-1 psql -U postgres -c "
CREATE TABLE q4_tumbling_pickup (
    window_start TIMESTAMP, PULocationID INT, num_trips BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);
CREATE TABLE q5_session_pickup (
    window_start TIMESTAMP, window_end TIMESTAMP, PULocationID INT, num_trips BIGINT,
    PRIMARY KEY (window_start, window_end, PULocationID)
);
CREATE TABLE q6_tumbling_tip (
    window_start TIMESTAMP PRIMARY KEY, total_tip DOUBLE PRECISION
);"
```

Submit jobs from inside the jobmanager container (the `src/job/` directory is mounted at `/opt/src/job/`):

```bash
docker exec workshop-jobmanager-1 flink run -py /opt/src/job/q4_tumbling_pickup.py
docker exec workshop-jobmanager-1 flink run -py /opt/src/job/q5_session_pickup.py
docker exec workshop-jobmanager-1 flink run -py /opt/src/job/q6_tumbling_tip.py
```

**Critical Flink config for ALL jobs:**

```python
env.set_parallelism(1)  # green-trips has 1 partition — higher parallelism starves the watermark
```

**Critical Kafka source config for ALL jobs:**

```sql
'scan.startup.mode' = 'earliest-offset',
'scan.bounded.mode' = 'latest-offset'   -- ESSENTIAL for historical data
```

`scan.bounded.mode = latest-offset` tells Flink to stop reading when it reaches the end of the topic (like reading a book vs. waiting for new pages). When the source finishes, Flink advances the watermark to `MAX_WATERMARK`, which flushes all remaining open windows to Postgres. Without this, the job runs forever and late windows never close.

**Timestamps as strings:** The 2025 dataset stores datetimes as strings, not epoch milliseconds. Convert in the source DDL:

```sql
lpep_pickup_datetime VARCHAR,
event_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd HH:mm:ss'),
WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECOND
```

---

#### Q4 — Tumbling Window: Pickup Location

**Concept:** A tumbling window is a fixed-size, non-overlapping bucket. Every event falls into exactly one 5-minute bucket based on its timestamp.

Query after job finishes:

```sql
SELECT PULocationID, num_trips
FROM q4_tumbling_pickup
ORDER BY num_trips DESC
LIMIT 3;
```

---

#### Q5 — Session Window: Longest Streak

**Concept:** A session window has no fixed size. It groups events that happen close together (within 5 minutes of each other). When no event arrives for 5 minutes, the session closes.

Example: pickups at 10:00, 10:03, 10:07, 10:12 → one session (each gap < 5 min). Then nothing until 10:20 → session closes at 10:17 (12 min + 5 min gap).

**Gotcha — session merging with JDBC sink:** When a session extends (a new event arrives within the gap), Flink retracts the old result and emits a new one with an updated `window_end`. Since `window_end` is part of the primary key, the JDBC sink can't upsert in place — it leaves orphaned rows, undercounting the sum. To verify the correct answer, we computed session windows directly in Python:

```python
# Ground truth: 82 trips in the longest session → answer option: 81
```

---

#### Q6 — Tumbling Window: Largest Tip

**Concept:** Same as Q4 but 1-hour buckets and summing `tip_amount` across all locations per hour.

Query after job finishes:

```sql
SELECT window_start, total_tip
FROM q6_tumbling_tip
ORDER BY total_tip DESC
LIMIT 3;
```

---

## Homework Answers

| Q | Question | Answer |
|---|----------|--------|
| Q1 | Redpanda version | `v25.3.9` |
| Q2 | Time to send 49K messages | ~15 sec → **10 seconds** |
| Q3 | Trips with trip_distance > 5 | **8506** |
| Q4 | PULocationID with most trips in a 5-min window | **74** |
| Q5 | Trips in the longest session | **81** |
| Q6 | Hour with highest total tip amount | **2025-10-16 18:00:00** |

---

## Key Learnings

- **Redpanda = Kafka API**, no JVM, faster local startup — any `kafka-python` code works unchanged
- **Tumbling windows** = fixed buckets (every 5 min). **Session windows** = variable-size, close after a gap
- **Watermarks** are Flink's internal clock — they tell Flink "I've seen all events up to time T, safe to close windows before T"
- **`scan.bounded.mode = latest-offset`** is essential for historical data — without it, the watermark stalls and open windows never flush
- **`parallelism = 1`** is required when the topic has 1 partition — idle subtasks block watermark advancement
- **NaN in JSON** crashes Flink's deserializer — always replace with `null` before sending to Kafka
- **Session window + JDBC upsert** has edge cases when `window_end` changes during session merges — verify with direct Python computation when in doubt
- `rpk` is Redpanda's CLI — use it for topic creation, deletion, version checks, and cluster info
- Flink UI at `http://localhost:8081` shows running jobs, task parallelism, and exceptions in real time
