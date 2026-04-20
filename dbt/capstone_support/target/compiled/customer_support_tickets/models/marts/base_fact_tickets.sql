 -- CAMBIO CLAVE: Ahora es VISTA

WITH union_all AS (
    SELECT
        ticket_id::VARCHAR as ticket_id,
        customer_email::VARCHAR as customer_email,
        product::VARCHAR as product,
        ticket_channel::VARCHAR as channel,
        category::VARCHAR as category,
        priority::VARCHAR as priority,
        status::VARCHAR as status,
        ticket_created_date::DATE as ticket_created_date,
        first_response_time_hours::DOUBLE as first_response_time_hours,
        resolution_time_hours::DOUBLE as resolution_time_hours,
        customer_satisfaction_score::DOUBLE as customer_satisfaction_score,
        '200k'::VARCHAR as dataset_source
    FROM "support"."main_staging"."stg_tickets_200k"

    UNION ALL

    SELECT
        ticket_id::VARCHAR as ticket_id,
        customer_email::VARCHAR as customer_email,
        product::VARCHAR as product,
        ticket_channel::VARCHAR as channel,
        category::VARCHAR as category,
        priority::VARCHAR as priority,
        status::VARCHAR as status,
        ticket_created_date::DATE as ticket_created_date,
        first_response_time_hours::DOUBLE as first_response_time_hours,
        resolution_time_hours::DOUBLE as resolution_time_hours,
        customer_satisfaction_score::DOUBLE as customer_satisfaction_score,
        'original'::VARCHAR as dataset_source
    FROM "support"."main_staging"."stg_tickets"
)

SELECT * FROM union_all