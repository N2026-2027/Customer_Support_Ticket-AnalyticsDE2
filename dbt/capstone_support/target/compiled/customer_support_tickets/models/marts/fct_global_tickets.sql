

select
    -- 1. ID único (Surrogate Key) para conteos y joins en el Dashboard
    md5(cast(coalesce(cast(f.ticket_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(f.dataset_source as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as ticket_sk,
    
    -- 2. Lógica de SLA (Transforma 0/1 en etiquetas de texto para los gráficos)
    case 
        when f.sla_breached = 1 then 'SLA_Incumplido' 
        else 'SLA_Cumplido' 
    end as sla_status,

    -- 3. Todas las métricas confirmadas (satisfaction, resolution_time, complexity, etc.)
    f.*,
    
    -- 4. Dimensiones de tiempo desde dim_date
    d.year,
    d.month as month,      -- Requerido por la página SLA Deep Dive
    d.month as month_num,  -- Requerido por otras lógicas de ordenamiento
    
    -- 5. Nombre del mes (Para filtros y ejes X legibles en Streamlit)
    case d.month
        when 1 then 'January' when 2 then 'February' when 3 then 'March'
        when 4 then 'April' when 5 then 'May' when 6 then 'June'
        when 7 then 'July' when 8 then 'August' when 9 then 'September'
        when 10 then 'October' when 11 then 'November' when 12 then 'December'
    end as month_name,
    
    d.is_weekend
    
from "support_200k"."main"."fact_tickets" f
left join "support_200k"."main"."dim_date" d 
    on cast(f.ticket_created_date as date) = d.date_actual