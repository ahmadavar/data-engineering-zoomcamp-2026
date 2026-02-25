

select
    locationid,
    borough,
    zone,
    replace(service_zone, 'Boro', 'Green') as service_zone
from `electric-cosine-485318-f9`.`dbt_prod`.`taxi_zone_lookup`