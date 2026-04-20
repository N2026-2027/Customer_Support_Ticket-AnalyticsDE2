{{ config(materialized='table') }}

with tickets as (
    select * from {{ ref('base_fact_tickets') }}
),

dates as (
    select * from {{ ref('dim_date') }}
)

select
    t.*,
    d.month as month_name, 
    d.year as fiscal_year
from tickets t
left join dates d 
    on cast(t.ticket_created_date as date) = d.date_actual
