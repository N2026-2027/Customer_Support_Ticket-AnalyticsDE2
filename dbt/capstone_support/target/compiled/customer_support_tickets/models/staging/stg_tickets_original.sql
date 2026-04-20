

with raw_source as (
    -- Usa source para que dbt entienda la dependencia
    select * from "support_original"."main"."customer_support_tickets"
)

select
    cast("Ticket ID" as varchar) as ticket_id,
    "Customer Email" as customer_email,
    lower(trim("Product Purchased")) as product,
    lower(trim("Ticket Channel")) as channel,
    lower(trim("Ticket Type")) as category,
    lower(trim("Ticket Priority")) as priority,
    lower(trim("Ticket Status")) as status,
    cast("Date of Purchase" as date) as ticket_created_date,
    
    -- Cálculos de tiempo
    cast(null as date) as ticket_resolved_date,
    (extract(epoch from cast("First Response Time" as timestamp)) / 3600.0) as first_response_time_hours,
    (extract(epoch from cast("Time to Resolution" as timestamp)) / 3600.0) as resolution_time_hours,
    cast("Customer Satisfaction Rating" as double) as customer_satisfaction_score,
    
    -- Columnas faltantes para igualar al dataset 200k
    cast(null as integer) as issue_complexity_score,
    false as escalated,
    false as sla_breached,
    cast(null as integer) as previous_tickets,
    
    'original' as dataset_source,
    current_timestamp as _ingested_at
from raw_source