
  
    
    

    create  table
      "support_200k"."main"."fact_tickets__dbt_tmp"
  
    as (
      

with tickets as (
    select * from "support_200k"."main"."base_fact_tickets"
),

dates as (
    select * from "support_200k"."main"."dim_date"
)

select
    t.*,
    d.month as month_name, 
    d.year as fiscal_year
from tickets t
left join dates d 
    on cast(t.ticket_created_date as date) = d.date_actual
    );
  
  