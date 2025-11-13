{{
  config(
    materialized='view'
  )
}}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('int_orders_enriched') }}
),

-- Aggregate customer metrics
customer_metrics as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_order_value) as lifetime_value,
        avg(total_order_value) as avg_order_value,
        min(order_purchase_timestamp) as first_order_date,
        max(order_purchase_timestamp) as last_order_date,
        avg(total_delivery_days) as avg_delivery_days,
        sum(case when order_status = 'delivered' then 1 else 0 end) as delivered_orders,
        sum(case when order_status = 'canceled' then 1 else 0 end) as canceled_orders,
        sum(case when delivery_status = 'late' then 1 else 0 end) as late_deliveries
    from orders
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        
        -- Customer metrics
        cm.total_orders,
        cm.lifetime_value,
        cm.avg_order_value,
        cm.first_order_date,
        cm.last_order_date,
        cm.avg_delivery_days,
        cm.delivered_orders,
        cm.canceled_orders,
        cm.late_deliveries,
        
        -- Customer segmentation
        extract(epoch from (cm.last_order_date - cm.first_order_date))/86400 as customer_tenure_days,
        
        case 
            when cm.total_orders >= 5 then 'loyal'
            when cm.total_orders >= 2 then 'repeat'
            else 'one_time'
        end as customer_segment,
        
        case
            when cm.lifetime_value >= 1000 then 'high_value'
            when cm.lifetime_value >= 500 then 'medium_value'
            else 'low_value'
        end as value_segment,
        
        -- Calculate late delivery rate
        case 
            when cm.delivered_orders > 0 
            then round(cm.late_deliveries::numeric / cm.delivered_orders::numeric, 2)
            else 0
        end as late_delivery_rate
        
    from customers c
    left join customer_metrics cm on c.customer_id = cm.customer_id
)

select * from final
