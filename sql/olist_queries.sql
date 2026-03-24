--E-Commerce Analysis Project

--Goal:
--Analyze sales performance, customer behavior, product revenue,
--delivery performance, and geographic revenue distribution.

--Tools: PostgreSQL
--Dataset: Brazilian E-commerce Public Dataset by Olist

select * from customers limit 10;
select * from order_items limit 10;
select * from orders limit 10;
select * from payments limit 10;
select * from products limit 10;
select * from reviews limit 10;

-- Data Cleaning

select column_name, data_type
from information_schema.columns
where table_name = 'orders';

-----------------------------------------------

select order_purchase_timestamp
from orders
limit 5;

alter table orders 
alter column order_purchase_timestamp
type timestamp
using order_purchase_timestamp::timestamp;

alter table orders
alter column order_approved_at type timestamp 
using nullif(order_approved_at, '')::timestamp,
alter column order_delivered_carrier_date type timestamp 
using nullif(order_delivered_carrier_date, '')::timestamp,
alter column order_delivered_customer_date type timestamp 
using nullif(order_delivered_customer_date, '')::timestamp,
alter column order_estimated_delivery_date type timestamp 
using nullif(order_estimated_delivery_date, '')::timestamp;

-- Business Overview

select min(order_purchase_timestamp) as first_order,
       max(order_purchase_timestamp) as last_order,
       count(*) as total_orders
from orders;

-----------------------------------------------

select date_trunc('month', order_purchase_timestamp) as month,
       count(*) as total_orders
from orders
group by month
order by month;

--REVENUE ANALYSIS
-------------------------------------------------------------------------
select SUM(payment_value) as total_revenue
from payments;

-- Monthly Revenue

select to_char(date_trunc('month', o.order_purchase_timestamp), 'yyyy-mm') as month,
       round(SUM(p.payment_value)::numeric, 2) as monthly_revenue
from orders o
join payments p on o.order_id = p.order_id 
group by month
order by month asc;

--AOV average order value
 
select round((sum(payment_value) / count(distinct order_id))::numeric, 2) as average_order_value
from payments;

--Monthly AOV
select to_char(date_trunc('month', o.order_purchase_timestamp), 'yyyy-mm') as month,
    ROUND((sum(p.payment_value) / count(distinct o.order_id))::numeric, 2) as monthly_aov
from orders o
join payments p on o.order_id=p.order_id
group by month
order by month;

--Top 5 months with highest revenue
select to_char(date_trunc('month', o.order_purchase_timestamp), 'yyyy-mm') as month,
       round(sum(p.payment_value)::numeric, 2) as monthly_revenue
from orders o
join payments p on o.order_id = p.order_id 
group by month
order by monthly_revenue desc
limit 5;

--Product Analysis
--------------------------------------------------------------------------------
--Which top 10 products generate the most revenue?
select product_id,
       round(sum(price)::numeric, 2) as total_revenue
from order_items
group by product_id
order by total_revenue desc
limit 10;

--Which product categories generate the most revenue?
select pr.product_category_name,
       round(sum(oi.price)::numeric, 2) as total_revenue
from products pr
join order_items oi on oi.product_id=pr.product_id 
where pr.product_category_name is not null
group by pr.product_category_name
order by total_revenue desc
limit 10;

--Delivery & Order Performance Analysis
-------------------------------------------------------------------------
--Real Delivery Time (Actual Performance)
select order_id,
      extract(day from (order_delivered_customer_date - order_purchase_timestamp))||' days' as delivery_time
from orders
where order_delivered_customer_date is not null;

--AVG delivery time
select avg(delivery_time) as average_delivery_time
from(select order_id,
       (order_delivered_customer_date - order_purchase_timestamp) as delivery_time
     from orders
     where order_delivered_customer_date is not null) s;
     
--How often are orders delivered later than the estimated delivery date?
select delivery_status,
       count(*) as total_orders,
       round(100.0 * count(*) / sum(count(*)) over(),1) as percentage
from(
     select order_id,
     case when order_delivered_customer_date <= order_estimated_delivery_date then 'on_time'
     else 'late'
     end as delivery_status
     from orders
     where order_delivered_customer_date is not null
     ) p
group by delivery_status;

--Revenue by State
------------------------------------------------------------------------------
--Which states generate the highest revenue?
select c.customer_state,
       round(sum(p.payment_value)::numeric, 2)as revenue,
       round((
100.0 * sum(p.payment_value) / sum(sum(p.payment_value)) over())::numeric,
1
) as percentage
from customers c
join orders o on o.customer_id=c.customer_id 
join payments p on p.order_id=o.order_id 
group by c.customer_state
order by revenue desc
limit 10;

--Customer lifetime value
select c.customer_unique_id,
       count(distinct o.order_id) as total_orders,
       round(sum(p.payment_value)::numeric, 2) as lifetime_value
from customers c
join orders o on o.customer_id=c.customer_id 
join payments p on p.order_id=o.order_id 
group by c.customer_unique_id
order by lifetime_value desc
limit 10;








