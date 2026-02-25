
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select vendorid
from `electric-cosine-485318-f9`.`dbt_prod`.`stg_green_tripdata`
where vendorid is null



  
  
      
    ) dbt_internal_test