{{ config(materialized='table') }}

-- CTE 1: Traemos los datos crudos con los nombres confirmados
with raw_source as (
    select
        ticket_id,
        customer_name,
        customer_email,
        product,
        category,
        issue_description,
        resolution_notes,
        priority,
        status,
        channel,
        region,
        customer_age,
        customer_gender,
        subscription_type,
        customer_tenure_months,
        previous_tickets,
        customer_satisfaction_score,
        first_response_time_hours,
        resolution_time_hours,
        ticket_created_date,
        ticket_resolved_date,
        escalated,
        sla_breached,
        operating_system,
        browser,
        payment_method,
        language,
        preferred_contact_time,
        issue_complexity_score,
        customer_segment
    from {{ ref('stg_tickets_200k') }}
),

-- CTE 2: Aplicamos CAST, COALESCE y limpieza
final_formatted as (
    select
        -- Identificadores y Cliente
        cast(ticket_id as varchar) as ticket_id,
        cast(customer_name as varchar) as customer_name,
        lower(trim(cast(customer_email as varchar))) as customer_email,
        
        -- Producto y Categorización
        lower(trim(cast(product as varchar))) as product,
        lower(trim(cast(category as varchar))) as category,
        cast(issue_description as varchar) as issue_description,
        cast(resolution_notes as varchar) as resolution_notes,
        
        -- Estado y Prioridad
        lower(trim(cast(priority as varchar))) as priority,
        lower(trim(cast(status as varchar))) as status,
        lower(trim(cast(channel as varchar))) as channel,
        cast(region as varchar) as region,
        
        -- Demografía y Perfil
        coalesce(cast(customer_age as integer), 0) as customer_age,
        cast(customer_gender as varchar) as customer_gender,
        cast(subscription_type as varchar) as subscription_type,
        cast(customer_tenure_months as integer) as customer_tenure_months,
        cast(customer_segment as varchar) as customer_segment,
        
        -- Métricas de Performance
        cast(previous_tickets as integer) as previous_tickets,
        coalesce(cast(customer_satisfaction_score as integer), 0) as customer_satisfaction_score,
        coalesce(cast(first_response_time_hours as double), 0.0) as first_response_time_hours,
        coalesce(cast(resolution_time_hours as double), 0.0) as resolution_time_hours,
        cast(issue_complexity_score as integer) as issue_complexity_score,
        
        -- Fechas y Flags
        cast(ticket_created_date as timestamp) as ticket_created_date,
        cast(ticket_resolved_date as timestamp) as ticket_resolved_date,
        cast(escalated as boolean) as escalated,
        cast(sla_breached as boolean) as sla_breached,
        
        -- Datos Técnicos y Preferencias
        cast(operating_system as varchar) as operating_system,
        cast(browser as varchar) as browser,
        cast(payment_method as varchar) as payment_method,
        cast(language as varchar) as language,
        cast(preferred_contact_time as varchar) as preferred_contact_time,
        
        -- Metadatos
        '200k' as dataset_source,
        current_timestamp as _ingested_at
    from raw_source
)

-- SELECT FINAL
select * from final_formatted
