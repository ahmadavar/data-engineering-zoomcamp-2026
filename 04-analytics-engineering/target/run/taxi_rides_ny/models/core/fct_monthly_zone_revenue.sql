
  
    

    create or replace table `electric-cosine-485318-f9`.`dbt_prod`.`fct_monthly_zone_revenue`
      
    
    

    
    OPTIONS()
    as (
      

with trips_data as (
    select * from `electric-cosine-485318-f9`.`dbt_prod`.`fact_trips`
)

select
    -- revenue grouping
    pickup_zones.zone as revenue_zone,
    timestamp_trunc(
        cast(pickup_datetime as timestamp),
        month
    ) as revenue_month,
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
inner join `electric-cosine-485318-f9`.`dbt_prod`.`dim_zones` as pickup_zones
    on trips_data.pickup_locationid = pickup_zones.locationid
group by 1, 2, 3
    );
  