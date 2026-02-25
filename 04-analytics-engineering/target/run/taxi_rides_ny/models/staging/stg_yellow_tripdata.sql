

  create or replace view `electric-cosine-485318-f9`.`dbt_prod`.`stg_yellow_tripdata`
  OPTIONS()
  as 

select
    -- identifiers
    to_hex(md5(cast(coalesce(cast(vendorid as string), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(tpep_pickup_datetime as string), '_dbt_utils_surrogate_key_null_') as string))) as tripid,
    cast(vendorid as integer) as vendorid,
    cast(ratecodeid as integer) as ratecodeid,
    cast(pulocationid as integer) as pickup_locationid,
    cast(dolocationid as integer) as dropoff_locationid,

    -- timestamps
    cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as numeric) as trip_distance,

    -- payment info
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type,
    case payment_type
        when 1 then 'Credit card'
        when 2 then 'Cash'
        when 3 then 'No charge'
        when 4 then 'Dispute'
        when 5 then 'Unknown'
        when 6 then 'Voided trip'
        else 'EMPTY'
    end as payment_type_description,
    cast(congestion_surcharge as numeric) as congestion_surcharge

from `electric-cosine-485318-f9`.`03_warehouse`.`yellow_tripdata_external`
where vendorid is not null;

