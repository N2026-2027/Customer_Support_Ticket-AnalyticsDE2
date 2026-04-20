
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    ticket_id as unique_field,
    count(*) as n_records

from "support_200k"."main"."stg_tickets_200k"
where ticket_id is not null
group by ticket_id
having count(*) > 1



  
  
      
    ) dbt_internal_test