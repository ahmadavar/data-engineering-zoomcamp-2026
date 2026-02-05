from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'ahmad',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'hello_module2',
    default_args=default_args,
    description='Test DAG',
    schedule=None,
    catchup=False,
    tags=['module2', 'test'],
)

def say_hello():
    print("🚀 Airflow is working!")
    return "Success!"

hello_task = PythonOperator(
    task_id='say_hello',
    python_callable=say_hello,
    dag=dag,
)
