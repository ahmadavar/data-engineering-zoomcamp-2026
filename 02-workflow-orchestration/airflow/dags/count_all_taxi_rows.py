from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import os

default_args = {
    'owner': 'ahmad',
    'start_date': datetime(2020, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'count_all_taxi_rows',
    default_args=default_args,
    description='Count total rows - answers Q3, Q4, Q5',
    schedule=None,
    catchup=False,
    tags=['homework', 'q3', 'q4', 'q5'],
)

def count_year_rows(**context):
    """Count rows for entire year or single month"""
    taxi_type = context['dag_run'].conf.get('taxi_type', 'yellow')
    year = context['dag_run'].conf.get('year', 2020)
    single_month = context['dag_run'].conf.get('month', None)
    
    total_rows = 0
    
    if single_month:
        # Single month (for Q5)
        months = [single_month]
    else:
        # All 12 months (for Q3, Q4)
        months = range(1, 13)
    
    for month in months:
        month_str = f"{month:02d}"
        filename = f"{taxi_type}_tripdata_{year}-{month_str}.csv"
        url = f"https://github.com/DataTalksClub/nyc-tlc-data/releases/download/{taxi_type}/{filename}"
        
        filepath = f"/tmp/{filename}"
        
        try:
            print(f"📥 Downloading {filename}...")
            response = requests.get(url, timeout=300)
            response.raise_for_status()
            
            with open(filepath, 'wb') as f:
                f.write(response.content)
            
            with open(filepath, 'r') as f:
                rows = sum(1 for line in f) - 1
            
            print(f"✅ {filename}: {rows:,} rows")
            total_rows += rows
            
            os.remove(filepath)
        except Exception as e:
            print(f"⚠️ Skipped {filename}: {e}")
    
    print("=" * 70)
    if single_month:
        print(f"📊 HOMEWORK Q5 ANSWER:")
        print(f"📊 {taxi_type.upper()} {year}-{single_month:02d}: {total_rows:,} rows")
    else:
        if taxi_type == 'yellow' and year == 2020:
            print(f"📊 HOMEWORK Q3 ANSWER:")
        elif taxi_type == 'green' and year == 2020:
            print(f"📊 HOMEWORK Q4 ANSWER:")
        print(f"📊 TOTAL ROWS FOR {taxi_type.upper()} {year}: {total_rows:,}")
    print("=" * 70)
    
    return total_rows

count_task = PythonOperator(
    task_id='count_all_rows',
    python_callable=count_year_rows,
    provide_context=True,
    dag=dag,
)
