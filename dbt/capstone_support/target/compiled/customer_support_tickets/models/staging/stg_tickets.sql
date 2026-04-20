

with src as (
    select * from "support_original"."main"."customer_support_tickets"
)

select
    cast(src."Ticket ID" as varchar) as ticket_id,
    src."Customer Email" as customer_email, -- Agregado para el JOIN de fct_tickets
    lower(trim(src."Product Purchased")) as product,
    lower(trim(src."Ticket Channel")) as ticket_channel,
    lower(trim(src."Ticket Type")) as category,   -- Renombrado para que coincida con fct_tickets
    lower(trim(src."Ticket Status")) as status,     -- Renombrado para que coincida con fct_tickets
    lower(trim(src."Ticket Priority")) as priority, -- Renombrado para que coincida con fct_tickets
    
    cast(src."Customer Satisfaction Rating" as double) as customer_satisfaction_score,
    cast(src."Date of Purchase" as date) as ticket_created_date,
    
    -- Columnas que no existen en el original pero fct_tickets pide (llenar con NULL o default)
    cast(null as date) as ticket_resolved_date,
    cast(null as double) as first_response_time_hours,
    cast(null as double) as resolution_time_hours,
    cast(null as integer) as issue_complexity_score,
    false as escalated,
    false as sla_breached,
    cast(null as integer) as previous_tickets,

    current_timestamp as _ingested_at,
    'original' as dataset_source
from src