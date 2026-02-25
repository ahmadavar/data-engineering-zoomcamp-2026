
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select tripid
from `electric-cosine-485318-f9`.`dbt_prod`.`stg_yellow_tripdata`
where tripid is null



  
  
      
    ) dbt_internal_test