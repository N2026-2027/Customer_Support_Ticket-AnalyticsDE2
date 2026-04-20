
  
  create view "support_200k"."main"."stg_tickets_200k__dbt_tmp" as (
    

with raw_source as (
    select * from "support_200k"."main"."customer_support_tickets_200k"
)

select
    -- Identificadores y Cliente
    ticket_id::varchar as ticket_id,
    customer_name,
    customer_email,
    customer_age,
    customer_gender,
    customer_segment,
    customer_tenure_months,
    
    -- Producto y Ticket
    lower(trim(product)) as product,
    category,
    issue_description,
    resolution_notes,
    priority,
    status,
    channel,
    region,
    
    -- Métricas y Rendimiento
    previous_tickets,
    customer_satisfaction_score,
    first_response_time_hours,
    resolution_time_hours,
    issue_complexity_score,
    
    -- Fechas y Logs
    ticket_created_date,
    ticket_resolved_date,
    escalated,
    sla_breached,
    
    -- Otros Atributos
    subscription_type,
    operating_system,
    browser,
    payment_method,
    language,
    preferred_contact_time,

    -- Metadatos
    '200k' as dataset_source,
    current_timestamp as _ingested_at
from raw_source
  );
