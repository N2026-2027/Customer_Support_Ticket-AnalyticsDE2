
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        priority as value_field,
        count(*) as n_records

    from "support_200k"."main"."stg_tickets_200k"
    group by priority

)

select *
from all_values
where value_field not in (
    'low','medium','high','critical'
)



  
  
      
    ) dbt_internal_test