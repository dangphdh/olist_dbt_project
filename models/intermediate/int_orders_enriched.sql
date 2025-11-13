{{
  config(
    materialized='view'
  )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

payments as (
    select * from {{ ref('stg_order_payments') }}
),

-- Aggregate order items
order_items_agg as (
    select
        order_id,
        count(*) as item_count,
        sum(price) as total_item_price,
        sum(freight_value) as total_freight_value,
        sum(price + freight_value) as total_order_value
    from order_items
    group by order_id
),

-- Aggregate payments
payments_agg as (
    select
        order_id,
        count(*) as payment_count,
        sum(payment_value) as total_payment_value,
        max(case when payment_type = 'credit_card' then 1 else 0 end) as has_credit_card,
        max(case when payment_type = 'boleto' then 1 else 0 end) as has_boleto,
        max(case when payment_type = 'voucher' then 1 else 0 end) as has_voucher,
        max(case when payment_type = 'debit_card' then 1 else 0 end) as has_debit_card
    from payments
    group by order_id
),

final as (
    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        
        -- Calculated fields
        extract(epoch from (o.order_approved_at - o.order_purchase_timestamp))/3600 as hours_to_approval,
        extract(epoch from (o.order_delivered_carrier_date - o.order_approved_at))/86400 as days_to_carrier,
        extract(epoch from (o.order_delivered_customer_date - o.order_delivered_carrier_date))/86400 as days_in_transit,
        extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400 as total_delivery_days,
        extract(epoch from (o.order_estimated_delivery_date - o.order_delivered_customer_date))/86400 as days_early_late,
        
        case 
            when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 'on_time'
            when o.order_delivered_customer_date > o.order_estimated_delivery_date then 'late'
            else 'pending'
        end as delivery_status,
        
        -- Order items aggregation
        coalesce(oi.item_count, 0) as item_count,
        coalesce(oi.total_item_price, 0) as total_item_price,
        coalesce(oi.total_freight_value, 0) as total_freight_value,
        coalesce(oi.total_order_value, 0) as total_order_value,
        
        -- Payment aggregation
        coalesce(p.payment_count, 0) as payment_count,
        coalesce(p.total_payment_value, 0) as total_payment_value,
        coalesce(p.has_credit_card, 0)::boolean as has_credit_card,
        coalesce(p.has_boleto, 0)::boolean as has_boleto,
        coalesce(p.has_voucher, 0)::boolean as has_voucher,
        coalesce(p.has_debit_card, 0)::boolean as has_debit_card
        
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join order_items_agg oi on o.order_id = oi.order_id
    left join payments_agg p on o.order_id = p.order_id
)

select * from final
