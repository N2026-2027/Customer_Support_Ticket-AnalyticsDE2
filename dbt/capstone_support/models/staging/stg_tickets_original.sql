SELECT 
    ticket_id,
    customer_name,
    category,
    priority,
    status,
    resolution_time_hours,
    'original' as dataset_source
FROM {{ source('raw_data', 'customer_support_tickets_200k') }}
