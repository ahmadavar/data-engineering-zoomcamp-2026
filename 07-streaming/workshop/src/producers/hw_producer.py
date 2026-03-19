import json
from time import time
from pathlib import Path

import pandas as pd
from kafka import KafkaProducer

DATA_FILE = Path(__file__).parent.parent.parent / "green_tripdata_2025-10.parquet"

COLUMNS = [
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount',
    'total_amount',
]

df = pd.read_parquet(DATA_FILE, columns=COLUMNS)

# Convert datetime columns to strings
for col in ['lpep_pickup_datetime', 'lpep_dropoff_datetime']:
    df[col] = df[col].astype(str)

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
)

t0 = time()

for _, row in df.iterrows():
    # Replace NaN with None so JSON serializes as null
    record = {k: (None if pd.isna(v) else v) for k, v in row.to_dict().items()}
    producer.send('green-trips', value=record)

producer.flush()

t1 = time()
print(f'Sent {len(df)} messages in {(t1 - t0):.2f} seconds')
