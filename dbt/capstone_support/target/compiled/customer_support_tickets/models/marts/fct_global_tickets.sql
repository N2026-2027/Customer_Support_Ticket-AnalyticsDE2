

select
    f.*,
    d.year,
    d.month as month_num, -- Cambiado de month_name a month (la columna real)
    d.is_weekend
from "support_200k"."main"."fact_tickets" f
left join "support_200k"."main"."dim_date" d 
    on cast(f.ticket_created_date as date) = d.date_actual