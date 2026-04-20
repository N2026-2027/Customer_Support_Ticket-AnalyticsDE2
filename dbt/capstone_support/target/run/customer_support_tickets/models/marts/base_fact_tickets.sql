
  
    
    

    create  table
      "support_200k"."main"."base_fact_tickets__dbt_tmp"
  
    as (
      

-- CTE 1: Importación de datos crudos (Referenciando las columnas reales)
WITH staging_data AS (
    SELECT * FROM "support_200k"."main"."stg_tickets_200k"
),

-- CTE 2: Limpieza, Casteo y Manejo de Nulos
cleaned_data AS (
    SELECT
        COALESCE(CAST(ticket_id AS VARCHAR), 'N/A')       AS ticket_id,
        CAST(customer_name AS VARCHAR)                    AS customer_name,
        LOWER(TRIM(CAST(customer_email AS VARCHAR)))      AS customer_email,
        LOWER(TRIM(CAST(product AS VARCHAR)))             AS product,
        LOWER(TRIM(CAST(category AS VARCHAR)))            AS category,
        CAST(issue_description AS VARCHAR)                AS issue_description,
        CAST(resolution_notes AS VARCHAR)                 AS resolution_notes,
        LOWER(TRIM(CAST(priority AS VARCHAR)))            AS priority,
        LOWER(TRIM(CAST(status AS VARCHAR)))              AS status,
        LOWER(TRIM(CAST(channel AS VARCHAR)))             AS channel,
        CAST(region AS VARCHAR)                           AS region,
        COALESCE(CAST(customer_age AS INTEGER), 0)        AS customer_age,
        CAST(customer_gender AS VARCHAR)                  AS customer_gender,
        CAST(subscription_type AS VARCHAR)                AS subscription_type,
        CAST(customer_tenure_months AS INTEGER)           AS customer_tenure_months,
        CAST(previous_tickets AS INTEGER)                 AS previous_tickets,
        COALESCE(CAST(customer_satisfaction_score AS INTEGER), 0) AS customer_satisfaction_score,
        COALESCE(CAST(first_response_time_hours AS DOUBLE), 0.0)  AS first_response_time_hours,
        COALESCE(CAST(resolution_time_hours AS DOUBLE), 0.0)      AS resolution_time_hours,
        CAST(ticket_created_date AS TIMESTAMP)            AS ticket_created_date,
        CAST(ticket_resolved_date AS TIMESTAMP)           AS ticket_resolved_date,
        CAST(escalated AS BOOLEAN)                        AS escalated,
        CAST(sla_breached AS BOOLEAN)                     AS sla_breached,
        CAST(operating_system AS VARCHAR)                 AS operating_system,
        CAST(browser AS VARCHAR)                          AS browser,
        CAST(payment_method AS VARCHAR)                   AS payment_method,
        CAST(language AS VARCHAR)                         AS language,
        CAST(preferred_contact_time AS VARCHAR)           AS preferred_contact_time,
        CAST(issue_complexity_score AS INTEGER)           AS issue_complexity_score,
        CAST(customer_segment AS VARCHAR)                 AS customer_segment
    FROM staging_data
),

-- CTE 3: Lógica de Negocio y Metadatos
business_logic AS (
    SELECT
        c.*,
        -- Banderas de cumplimiento automáticas basadas en las horas confirmadas
        CASE WHEN c.first_response_time_hours <= 24 THEN 1 ELSE 0 END AS is_within_sla_first_response,
        CASE WHEN c.resolution_time_hours <= 72 THEN 1 ELSE 0 END     AS is_within_sla_resolution,
        
        -- Segmentación de edad
        CASE 
            WHEN c.customer_age < 25 THEN 'Gen Z'
            WHEN c.customer_age BETWEEN 25 AND 40 THEN 'Millennial'
            WHEN c.customer_age > 40 THEN 'Gen X/Boomer'
            ELSE 'Unknown'
        END AS age_segment,

        -- Metadatos
        '200k'                                            AS dataset_source,
        CURRENT_TIMESTAMP                                 AS _ingested_at
    FROM cleaned_data c
),

-- CTE 4: Deduplicación por ticket_id
final_deduplicated AS (
    SELECT 
        b.*,
        ROW_NUMBER() OVER (PARTITION BY b.ticket_id ORDER BY b.ticket_created_date DESC) AS row_num
    FROM business_logic b
)

-- Selección Final (Columnas confirmadas + pre-cálculos)
SELECT
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
    age_segment,
    customer_gender,
    subscription_type,
    customer_tenure_months,
    previous_tickets,
    customer_satisfaction_score,
    first_response_time_hours,
    is_within_sla_first_response,
    resolution_time_hours,
    is_within_sla_resolution,
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
    customer_segment,
    dataset_source,
    _ingested_at
FROM final_deduplicated
WHERE row_num = 1
    );
  
  