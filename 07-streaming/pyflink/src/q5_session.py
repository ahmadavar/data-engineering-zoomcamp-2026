import pandas as pd

df = pd.read_parquet('data/green_tripdata_2019-10.parquet')
df = df[['lpep_pickup_datetime', 'lpep_dropoff_datetime', 'PULocationID', 'DOLocationID']].dropna()
df = df.sort_values('lpep_dropoff_datetime').reset_index(drop=True)

# Simulate session windows: new session when gap > 5 minutes in global stream
gap = pd.Timedelta('5 minutes')
df['time_diff'] = df['lpep_dropoff_datetime'].diff()
df['new_session'] = (df['time_diff'] > gap) | df['time_diff'].isna()
df['session_id'] = df['new_session'].cumsum()

# Count trips per session per PU/DO pair
result = df.groupby(['session_id', 'PULocationID', 'DOLocationID']).size().reset_index(name='num_trips')
top = result.sort_values('num_trips', ascending=False).head(5)
print(top.to_string(index=False))
