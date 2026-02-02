#!/usr/bin/env python3
"""Execute all homework queries and display answers."""

import pandas as pd
from sqlalchemy import create_engine

def main():
    print("=" * 70)
    print("MODULE 1 HOMEWORK - ALL ANSWERS")
    print("=" * 70)
    print()
    
    engine = create_engine('postgresql://postgres:root@localhost:5432/ny_taxi')
    
    # Q1 & Q2 (theory)
    print("Q1: pip version in python:3.13")
    print("Answer: 25.3\n")
    
    print("Q2: Docker networking hostname:port")
    print("Answer: db:5432\n")
    
    # Q3
    q3 = pd.read_sql("""
        SELECT COUNT(*) as answer
        FROM green_taxi_trips
        WHERE lpep_pickup_datetime >= '2025-11-01'
          AND lpep_pickup_datetime < '2025-12-01'
          AND trip_distance <= 1.0
    """, engine)
    print(f"Q3: Short trips (≤1 mile): {q3['answer'].iloc[0]:,}\n")
    
    # Q4
    q4 = pd.read_sql("""
        SELECT 
            DATE(lpep_pickup_datetime) as date,
            MAX(trip_distance) as distance
        FROM green_taxi_trips
        WHERE trip_distance < 100
        GROUP BY DATE(lpep_pickup_datetime)
        ORDER BY distance DESC
        LIMIT 1
    """, engine)
    print(f"Q4: Longest trip day: {q4['date'].iloc[0]}\n")
    
    # Q5
    q5 = pd.read_sql("""
        SELECT 
            z."Zone" as zone,
            SUM(t.total_amount) as total
        FROM green_taxi_trips t
        JOIN taxi_zones z ON t."PULocationID" = z."LocationID"
        WHERE DATE(t.lpep_pickup_datetime) = '2025-11-18'
        GROUP BY z."Zone"
        ORDER BY total DESC
        LIMIT 1
    """, engine)
    print(f"Q5: Largest pickup zone (Nov 18): {q5['zone'].iloc[0]}\n")
    
    # Q6
    q6 = pd.read_sql("""
        SELECT 
            dz."Zone" as zone,
            MAX(t.tip_amount) as tip
        FROM green_taxi_trips t
        JOIN taxi_zones pz ON t."PULocationID" = pz."LocationID"
        JOIN taxi_zones dz ON t."DOLocationID" = dz."LocationID"
        WHERE pz."Zone" = 'East Harlem North'
          AND t.lpep_pickup_datetime >= '2025-11-01'
          AND t.lpep_pickup_datetime < '2025-12-01'
        GROUP BY dz."Zone"
        ORDER BY tip DESC
        LIMIT 1
    """, engine)
    print(f"Q6: Largest tip dropoff: {q6['zone'].iloc[0]}\n")
    
    # Q7
    print("Q7: Terraform workflow")
    print("Answer: terraform init, terraform apply -auto-approve, terraform destroy\n")
    
    print("=" * 70)
    print("DONE! Copy these answers to your homework submission.")
    print("=" * 70)

if __name__ == '__main__':
    main()
