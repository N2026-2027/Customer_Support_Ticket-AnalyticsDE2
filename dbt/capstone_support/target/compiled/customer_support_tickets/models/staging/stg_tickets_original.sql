SELECT 
    ticket_id,
    customer_name,
    category,
    priority,
    status,
    resolution_time_hours,
    'original' as dataset_source
FROM "support_200k"."main"."customer_support_tickets_200k"