{{ config(materialized='table') }}

with trips_data as (
    select * from {{ ref('fact_trips') }}
)

select
    -- revenue grouping
    pickup_zones.zone as revenue_zone,
    {{ dbt.date_trunc('month', 'pickup_datetime') }} as revenue_month,
    service_type,

    -- revenue calculation
    sum(fare_amount) as revenue_monthly_fare,
    sum(extra) as revenue_monthly_extra,
    sum(mta_tax) as revenue_monthly_mta_tax,
    sum(tip_amount) as revenue_monthly_tip_amount,
    sum(tolls_amount) as revenue_monthly_tolls_amount,
    sum(improvement_surcharge) as revenue_monthly_improvement_surcharge,
    sum(total_amount) as revenue_monthly_total_amount,
    sum(congestion_surcharge) as revenue_monthly_congestion_surcharge,

    -- count
    count(tripid) as total_monthly_trips,
    avg(passenger_count) as avg_monthly_passenger_count,
    avg(trip_distance) as avg_monthly_trip_distance

from trips_data
inner join {{ ref('dim_zones') }} as pickup_zones
    on trips_data.pickup_locationid = pickup_zones.locationid
group by 1, 2, 3
