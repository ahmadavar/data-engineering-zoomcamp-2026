#!/usr/bin/env python3
"""Load Module 1 homework data into PostgreSQL."""

import pandas as pd
from sqlalchemy import create_engine, text
from tqdm import tqdm
import sys

def main():
    print("=" * 70)
    print("MODULE 1 HOMEWORK - DATA LOADING")
    print("=" * 70)
    print()
    
    # Connect to database
    print("📡 Connecting to PostgreSQL...")
    engine = create_engine('postgresql://postgres:root@localhost:5432/ny_taxi')
    
    try:
        with engine.connect() as conn:
            print("✅ Connected successfully\n")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)
    
    # Load taxi zones
    print("1️⃣  LOADING TAXI ZONES")
    print("-" * 70)
    zones = pd.read_csv('data/taxi_zone_lookup.csv')
    print(f"✓ Read {len(zones)} zones")
    
    zones.to_sql('taxi_zones', engine, if_exists='replace', index=False)
    print(f"✅ Loaded {len(zones)} zones\n")
    
    # Load green taxi trips
    print("2️⃣  LOADING GREEN TAXI TRIPS")
    print("-" * 70)
    trips = pd.read_parquet('data/green_tripdata_2025-11.parquet')
    total_rows = len(trips)
    print(f"✓ Read {total_rows:,} trips")
    print(f"Date range: {trips['lpep_pickup_datetime'].min()} to {trips['lpep_pickup_datetime'].max()}\n")
    
    # Load in chunks
    print("Loading to database...")
    chunk_size = 5000
    
    for i in tqdm(range(0, len(trips), chunk_size), desc="Progress"):
        chunk = trips[i:i+chunk_size]
        if i == 0:
            chunk.to_sql('green_taxi_trips', engine, if_exists='replace', index=False)
        else:
            chunk.to_sql('green_taxi_trips', engine, if_exists='append', index=False)
    
    print(f"\n✅ Loaded {total_rows:,} trips\n")
    
    # Verify
    print("3️⃣  VERIFICATION")
    print("-" * 70)
    with engine.connect() as conn:
        zones_count = conn.execute(text("SELECT COUNT(*) FROM taxi_zones")).fetchone()[0]
        trips_count = conn.execute(text("SELECT COUNT(*) FROM green_taxi_trips")).fetchone()[0]
        print(f"✓ taxi_zones: {zones_count:,} rows")
        print(f"✓ green_taxi_trips: {trips_count:,} rows")
    
    print()
    print("🎉 DATA LOADING COMPLETE!")
    print("=" * 70)

if __name__ == '__main__':
    main()
