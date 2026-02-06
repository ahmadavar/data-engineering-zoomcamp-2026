# Module 2 – Workflow Orchestration (Airflow)

This module is part of the **Data Engineering Zoomcamp 2026** by [DataTalksClub](https://github.com/DataTalksClub).

The goal of this module is to learn how to orchestrate ETL pipelines using **Airflow**, including scheduling, backfills, variables, and workflow automation using NYC Taxi datasets.

---

## 📌 Topics Covered

- Workflow orchestration concepts
- Building ETL pipelines with Airflow
- Dynamic variables and templating
- Backfilling historical data
- Scheduling workflows with timezone support
- Processing NYC Yellow & Green Taxi data (2019–2021)

---

## 📊 Homework 2 – Quiz Answers

### Question 1
**Uncompressed file size of `yellow_tripdata_2020-12.csv`:**

✅ **364.7 MiB**

---

### Question 2
**Rendered value of the variable `file` when:**
- taxi = green
- year = 2020
- month = 04

✅ **green_tripdata_2020-04.csv**

---

### Question 3
**Total rows for Yellow Taxi data in 2020:**

✅ **24,648,499**

---

### Question 4
**Total rows for Green Taxi data in 2020:**

✅ **1,734,051**

---

### Question 5
**Rows in Yellow Taxi data for March 2021:**

✅ **1,925,152**

---

### Question 6
**Correct timezone configuration for New York:**

✅ **Add a timezone property set to `America/New_York`**

---

## ⚙️ Implementation Notes

- Extended workflows to include **2021 data**
- Processed data from **January to July 2021**
- Used Airflo backfill functionality for historical runs
- Handled both **Yellow** and **Green** taxi datasets
- DAGs and orchestration configs are stored in the `airflow/` directory

---

## 📚 Resources

- Course repo: https://github.com/DataTalksClub/data-engineering-zoomcamp
- Homework submission: https://courses.datatalks.club/de-zoomcamp-2026/homework/hw2
- NYC Taxi data: https://github.com/DataTalksClub/nyc-tlc-data

---

## 🙌 Acknowledgements

Thanks to **DataTalksClub**, **Alexey Grigorev**, and **Will Russell** for the amazing course.
