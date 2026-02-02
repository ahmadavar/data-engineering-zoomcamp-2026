# Module 1 Homework: Docker & SQL

**Student:** Ahmad Naggayev
**Date:** January 27, 2026
**Environment:** GCP VM + PostgreSQL in Docker

---

## 📊 Homework Answers

### Question 1: Docker pip version

**Question:** What version of pip is installed in the `python:3.13` Docker image?

**Answer:** `25.3`

**How to verify:**
```bash
docker run --rm -it --entrypoint=bash python:3.13 -c 'pip --version'
```

---

### Question 2: Docker Networking

**Question:** In docker-compose, what hostname:port should pgAdmin use to connect to PostgreSQL?

**Answer:** `db:5432`

**Explanation:**
Within Docker Compose networks, containers communicate using:
- **Service name** (`db`) as hostname
- **Internal container port** (`5432`), not the host-mapped port

---

### Question 3: Short Trips Count

**Question:** How many trips in November 2025 had trip_distance ≤ 1 mile?

**Answer:** `[PASTE YOUR NUMBER HERE]`

**SQL Query:**
```sql
SELECT COUNT(*)
FROM green_taxi_trips
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance <= 1.0;
```

---

### Question 4: Longest Trip Day

**Question:** Which day had the longest trip (excluding errors > 100 miles)?

**Answer:** `[PASTE YOUR DATE HERE]`

**SQL Query:**
```sql
SELECT
    DATE(lpep_pickup_datetime) as pickup_date,
    MAX(trip_distance) as max_distance
FROM green_taxi_trips
WHERE trip_distance < 100
GROUP BY DATE(lpep_pickup_datetime)
ORDER BY max_distance DESC
LIMIT 1;
```

---

### Question 5: Largest Pickup Zone

**Question:** Which pickup zone had the largest total_amount on November 18, 2025?

**Answer:** `[PASTE YOUR ZONE HERE]`

**SQL Query:**
```sql
SELECT
    z."Zone",
    SUM(t.total_amount) as total_amount
FROM green_taxi_trips t
JOIN taxi_zones z ON t."PULocationID" = z."LocationID"
WHERE DATE(t.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z."Zone"
ORDER BY total_amount DESC
LIMIT 1;
```

---

### Question 6: Largest Tip

**Question:** For pickups from "East Harlem North", which dropoff zone had the largest tip?

**Answer:** `[PASTE YOUR ZONE HERE]`

**SQL Query:**
```sql
SELECT
    dz."Zone",
    MAX(t.tip_amount) as max_tip
FROM green_taxi_trips t
JOIN taxi_zones pz ON t."PULocationID" = pz."LocationID"
JOIN taxi_zones dz ON t."DOLocationID" = dz."LocationID"
WHERE pz."Zone" = 'East Harlem North'
  AND t.lpep_pickup_datetime >= '2025-11-01'
  AND t.lpep_pickup_datetime < '2025-12-01'
GROUP BY dz."Zone"
ORDER BY max_tip DESC
LIMIT 1;
```

---

### Question 7: Terraform Workflow

**Question:** What's the correct Terraform workflow sequence?

**Answer:** `terraform init, terraform apply -auto-approve, terraform destroy`

**Explanation:**
1. `terraform init` - Download providers, setup backend
2. `terraform apply -auto-approve` - Create resources without manual confirmation
3. `terraform destroy` - Remove all managed infrastructure

---

## 🏗️ Project Structure
```
01-docker-sql/
├── data/
│   ├── green_tripdata_2025-11.parquet
│   └── taxi_zone_lookup.csv
├── scripts/
│   ├── load_homework_data.py
│   └── get_all_answers.py
├── sql/
│   └── homework_answers.sql
├── README.md
└── pyproject.toml
```

---

## 🚀 How to Reproduce

### 1. Start PostgreSQL
```bash
docker run -d \
  --name postgres-homework \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=root \
  -e POSTGRES_DB=ny_taxi \
  -p 5432:5432 \
  postgres:17-alpine
```

### 2. Download Data
```bash
wget -O data/green_tripdata_2025-11.parquet \
  https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet
wget -O data/taxi_zone_lookup.csv \
  https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

### 3. Load Data
```bash
uv run python scripts/load_homework_data.py
```

### 4. Get Answers
```bash
uv run python scripts/get_all_answers.py
```

---

## 💻 Technologies Used

- **Cloud:** Google Cloud Platform (GCP VM)
- **Database:** PostgreSQL 17 (Alpine Linux)
- **Containerization:** Docker
- **Language:** Python 3.12
- **Package Manager:** uv
- **Libraries:** pandas, sqlalchemy, pyarrow

---

## 📚 What I Learned

- ✅ Docker containerization
- ✅ PostgreSQL setup and management
- ✅ SQL queries (JOINs, GROUP BY, aggregations)
- ✅ Python data loading with pandas
- ✅ Working with Parquet files
- ✅ Cloud-based development on GCP

---

**Repository:** - https://github.com/ahmadavar/data-engineering-zoomcamp-2026
