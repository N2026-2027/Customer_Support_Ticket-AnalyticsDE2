
  
    
    

    create  table
      "support"."main_marts"."fact_tickets__dbt_tmp"
  
    as (
      

-- 1. Preparamos el dataset de 200k con tipos fijos y nombres limpios
WITH base_200k AS (
    SELECT
        ticket_id::VARCHAR                    AS t_id,
        customer_email::VARCHAR               AS email,
        product::VARCHAR                      AS prod,
        ticket_channel::VARCHAR               AS chan,
        ticket_type::VARCHAR                  AS cat,
        ticket_priority::VARCHAR              AS prio,
        ticket_status::VARCHAR                AS stat,
        ticket_created_date::DATE             AS created_dt,
        CAST(NULL AS DATE)                    AS resolved_dt,
        -- Usamos DOUBLE por los decimales que se ven en tus fotos (ej: 38.5)
        first_response_time_hours::DOUBLE     AS frt_hrs,
        resolution_time_hours::DOUBLE         AS res_hrs,
        satisfaction_rating::DOUBLE           AS sat_score,
        '200k'::VARCHAR                       AS d_source
    FROM "support"."main_staging"."stg_tickets_200k"
),

-- 2. Preparamos el dataset original como un espejo exacto del anterior
base_original AS (
    SELECT
        ticket_id::VARCHAR                    AS t_id,
        customer_email::VARCHAR               AS email,
        product::VARCHAR                      AS prod,
        ticket_channel::VARCHAR               AS chan,
        category::VARCHAR                     AS cat,
        priority::VARCHAR                     AS prio,
        status::VARCHAR                       AS stat,
        ticket_created_date::DATE             AS created_dt,
        CAST(NULL AS DATE)                    AS resolved_dt,
        first_response_time_hours::DOUBLE     AS frt_hrs,
        resolution_time_hours::DOUBLE         AS res_hrs,
        customer_satisfaction_score::DOUBLE   AS sat_score,
        'original'::VARCHAR                   AS d_source
    FROM "support"."main_staging"."stg_tickets"
),

-- 3. Unión segura: DuckDB no puede fallar porque las "cajas" son idénticas
unioned AS (
    SELECT * FROM base_200k
    UNION ALL
    SELECT * FROM base_original
),

-- 4. Cruce con dimensiones
enriched AS (
    SELECT
        u.*,
        c.customer_sk,
        p.product_sk,
        tt.ticket_type_sk
    FROM unioned u
    LEFT JOIN "support"."main_marts"."dim_customer"    c  ON u.email = c.customer_email
    LEFT JOIN "support"."main_marts"."dim_product"     p  ON u.prod  = p.product 
                                              AND COALESCE(u.chan, 'unknown') = p.channel
    LEFT JOIN "support"."main_marts"."dim_ticket_type" tt ON u.cat   = tt.category 
                                              AND u.prio = tt.priority
)

-- 5. Selección final con lógica de negocio
SELECT
    md5(cast(coalesce(cast(t_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(d_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS ticket_sk,
    t_id                                 AS ticket_id,
    customer_sk,
    product_sk,
    ticket_type_sk,
    created_dt                           AS date_id,
    d_source                             AS dataset_source,
    stat                                 AS status,
    frt_hrs                              AS first_response_time_hours,
    res_hrs                              AS resolution_time_hours,
    sat_score                            AS customer_satisfaction_score,
    created_dt                           AS ticket_created_date,
    resolved_dt                          AS ticket_resolved_date,
    
    -- Campos calculados para Dashboards
    CASE WHEN res_hrs IS NOT NULL THEN TRUE ELSE FALSE END AS is_resolved,
    CASE 
        WHEN sat_score >= 4 THEN 'satisfied'
        WHEN sat_score >= 3 THEN 'neutral'
        ELSE 'unsatisfied'
    END                                  AS satisfaction_band,
    'SLA_Cumplido'                       AS sla_status

FROM enriched
    );
  
  