import json
import pandas as pd
from kafka import KafkaProducer
from time import time

def json_serializer(data):
    return json.dumps(data).encode('utf-8')

server = 'localhost:9092'

producer = KafkaProducer(
    bootstrap_servers=[server],
    value_serializer=json_serializer
)

# Q3: Test connection
print("Q3 - Connected:", producer.bootstrap_connected())

# Q4: Send green taxi data
df = pd.read_parquet('data/green_tripdata_2019-10.parquet')
df = df[['lpep_pickup_datetime', 'lpep_dropoff_datetime', 'PULocationID',
         'DOLocationID', 'passenger_count', 'trip_distance', 'tip_amount']]

t0 = time()

topic_name = 'green-trips'
for _, row in df.iterrows():
    message = {k: str(v) if hasattr(v, 'isoformat') else v for k, v in row.items()}
    producer.send(topic_name, value=message)

producer.flush()
t1 = time()

print(f"Q4 - Sent {len(df)} messages in {round(t1 - t0, 2)} seconds")
