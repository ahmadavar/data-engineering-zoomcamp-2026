import json
from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'green-trips',
    bootstrap_servers=['localhost:9092'],
    auto_offset_reset='earliest',
    value_deserializer=lambda v: json.loads(v.decode('utf-8')),
    consumer_timeout_ms=10000,  # stop after 10s of no messages
)

count = 0
total = 0

for msg in consumer:
    trip = msg.value
    total += 1
    if trip.get('trip_distance', 0) > 5.0:
        count += 1

print(f'Total trips: {total}')
print(f'Trips with trip_distance > 5: {count}')
