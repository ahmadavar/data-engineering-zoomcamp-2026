{{ config(materialized='table') }}

with green_data as (
    select
        tripid,
        vendorid,
        ratecodeid,
        pickup_locationid,
        dropoff_locationid,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        passenger_count,
        trip_distance,
        trip_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        ehail_fee,
        improvement_surcharge,
        total_amount,
        payment_type,
        payment_type_description,
        congestion_surcharge,
        'Green' as service_type
    from {{ ref('stg_green_tripdata') }}
),

yellow_data as (
    select
        tripid,
        vendorid,
        ratecodeid,
        pickup_locationid,
        dropoff_locationid,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        passenger_count,
        trip_distance,
        cast(null as integer) as trip_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        cast(null as numeric) as ehail_fee,
        improvement_surcharge,
        total_amount,
        payment_type,
        payment_type_description,
        congestion_surcharge,
        'Yellow' as service_type
    from {{ ref('stg_yellow_tripdata') }}
)

select * from green_data
union all
select * from yellow_data
