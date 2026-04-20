
  
  create view "support_200k"."main_staging"."stg_tickets_200k__dbt_tmp" as (
    

-- Lee de support_200k.duckdb  (source: raw_200k)
-- Headers snake_case nativos del CSV 200k

with source as (
    -- Ruta directa al catálogo de los 200k
    select * from support_200k.main.customer_support_tickets_200k
),

renamed as (
    select
        cast(ticket_id as varchar)                              as ticket_id,
        md5(cast(coalesce(cast(customer_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(customer_email as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))                                                   as customer_id,
        nullif(lower(trim(customer_name)),   '')                as customer_name,
        nullif(lower(trim(customer_email)),  '')                as customer_email,
        nullif(lower(trim(customer_gender)), '')                as customer_gender,
        try_cast(customer_age as integer)                       as customer_age,
        -- Exclusivos del 200k
        nullif(lower(trim(subscription_type)),      '')         as subscription_type,
        try_cast(customer_tenure_months as integer)             as customer_tenure_months,
        try_cast(previous_tickets as integer)                   as previous_tickets,
        nullif(lower(trim(customer_segment)),       '')         as customer_segment,
        nullif(lower(trim(region)),                 '')         as region,
        nullif(lower(trim(operating_system)),       '')         as operating_system,
        nullif(lower(trim(browser)),                '')         as browser,
        nullif(lower(trim(payment_method)),         '')         as payment_method,
        nullif(lower(trim(language)),               '')         as language,
        nullif(lower(trim(preferred_contact_time)), '')         as preferred_contact_time,
        try_cast(issue_complexity_score as integer)             as issue_complexity_score,
        try_cast(escalated    as boolean)                       as escalated,
        try_cast(sla_breached as boolean)                       as sla_breached,
        try_cast(ticket_resolved_date as date)                  as ticket_resolved_date,
        -- Dimensiones comunes
        nullif(lower(trim(product)),   '')                      as product,
        nullif(lower(trim(product)),   '')                      as product_purchased,
        nullif(lower(trim(category)),  '')                      as ticket_type,
        nullif(lower(trim(category)),  '')                      as category,
        nullif(lower(trim(status)),    '')                      as ticket_status,
        nullif(lower(trim(status)),    '')                      as status,
        nullif(lower(trim(priority)),  '')                      as ticket_priority,
        nullif(lower(trim(priority)),  '')                      as priority,
        nullif(lower(trim(channel)),   '')                      as ticket_channel,
        -- Métricas numéricas (NO timestamps en este dataset)
        try_cast(customer_satisfaction_score as double)         as satisfaction_rating,
        try_cast(customer_satisfaction_score as double)         as customer_satisfaction_score,
        try_cast(first_response_time_hours as double)           as first_response_hours,
        try_cast(first_response_time_hours as double)           as first_response_time_hours,
        try_cast(resolution_time_hours as double)               as resolution_time_hours,
        -- Flags de negocio
        (lower(trim(status)) = 'open')                          as is_open_no_response,
        (lower(trim(status)) not in ('closed','resolved'))      as is_unresolved,
        -- Fechas
        try_cast(ticket_created_date as date)                   as ticket_created_date,
        try_cast(ticket_created_date as date)                   as purchase_date,
        current_timestamp                                       as _ingested_at,
        '200k'                                                  as dataset_source
    from source
),

deduplicated as (
    select *,
        row_number() over (partition by ticket_id order by _ingested_at desc) as _rn
    from renamed
)

-- Columnas explícitas — _rn nunca sale del modelo
select
    ticket_id, customer_id, customer_name, customer_email,
    customer_gender, customer_age, subscription_type,
    customer_tenure_months, previous_tickets, customer_segment,
    region, operating_system, browser, payment_method, language,
    preferred_contact_time, issue_complexity_score, escalated,
    sla_breached, ticket_resolved_date, product, product_purchased,
    ticket_type, category, ticket_status, status, ticket_priority,
    priority, ticket_channel, satisfaction_rating,
    customer_satisfaction_score, first_response_hours,
    first_response_time_hours, resolution_time_hours,
    is_open_no_response, is_unresolved, ticket_created_date,
    purchase_date, _ingested_at, dataset_source
from deduplicated
where _rn = 1
  );
