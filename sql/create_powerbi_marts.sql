-- Удаляем представление pbi_dim_date, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_dim_date;

-- Создаем календарь для Power BI. Это справочник дат, который будет связан с фактическими таблицами.
CREATE VIEW pbi_dim_date AS
SELECT
    d.date AS date_key,
    d.date AS calendar_date,
    CAST(strftime('%Y', d.date) AS INTEGER) AS year,
    CAST(strftime('%m', d.date) AS INTEGER) AS month_number,
    strftime('%Y-%m', d.date) AS year_month,
    strftime('%Y-%m-01', d.date) AS month_start,
    CAST(strftime('%d', d.date) AS INTEGER) AS day_of_month,
    CAST(strftime('%w', d.date) AS INTEGER) AS day_of_week_sun_0,
    CASE strftime('%w', d.date)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday'
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        ELSE 'Saturday'
    END AS weekday_name,
    CASE
        WHEN strftime('%w', d.date) IN ('0', '6') THEN 1
        ELSE 0
    END AS is_weekend
FROM (
    SELECT DISTINCT date
    FROM fact_sales
) AS d;

-- Удаляем представление pbi_dim_store, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_dim_store;

-- Создаем справочник магазинов для Power BI.
CREATE VIEW pbi_dim_store AS
SELECT
    store_id,
    store_name,
    city
FROM dim_stores;

-- Удаляем представление pbi_dim_product, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_dim_product;

-- Создаем справочник товаров для Power BI.
CREATE VIEW pbi_dim_product AS
SELECT
    product_id,
    product_name,
    category,
    cost_price,
    sale_price,
    lead_time_days
FROM dim_products;

-- Удаляем представление pbi_fact_daily, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_fact_daily;

-- Создаем ежедневный факт продаж и остатков для Power BI. Это главная детальная таблица для дашборда.
CREATE VIEW pbi_fact_daily AS
SELECT
    m.date AS date_key,
    m.store_id,
    m.product_id,
    m.qty_sold,
    m.revenue,
    m.cogs,
    m.gross_profit,
    m.unconstrained_demand,
    m.lost_sales_qty,
    m.lost_revenue,
    m.potential_revenue,
    m.service_level,
    m.stock_qty,
    m.incoming_qty,
    m.is_stockout,
    m.in_stock_flag
FROM mart_daily_performance AS m;

-- Удаляем представление pbi_fact_store_daily_kpi, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_fact_store_daily_kpi;

-- Создаем ежедневные показатели по магазинам для Power BI.
CREATE VIEW pbi_fact_store_daily_kpi AS
SELECT
    date AS date_key,
    store_id,
    lines_count,
    qty_sold,
    revenue,
    gross_profit,
    lost_sales_qty,
    lost_revenue,
    potential_revenue,
    stock_qty,
    incoming_qty,
    stockout_lines,
    stockout_rate_pct,
    revenue_capture_pct
FROM mart_store_daily_kpi;

-- Удаляем представление pbi_fact_product_kpi, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_fact_product_kpi;

-- Создаем показатели по товарам за весь период для Power BI.
CREATE VIEW pbi_fact_product_kpi AS
SELECT
    product_id,
    total_qty_sold,
    total_revenue,
    total_gross_profit,
    total_lost_sales_qty,
    total_lost_revenue,
    total_potential_revenue,
    stockout_days,
    lost_revenue_pct
FROM mart_product_kpi;

-- Удаляем представление pbi_snapshot_stock_risk, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_snapshot_stock_risk;

-- Создаем срез текущего состояния запасов и риска дефицита для Power BI.
CREATE VIEW pbi_snapshot_stock_risk AS
SELECT
    snapshot_date AS date_key,
    store_id,
    product_id,
    stock_qty,
    incoming_qty,
    expected_available_qty,
    avg_daily_demand_14d,
    avg_daily_sales_14d,
    stockout_days_14d,
    lost_sales_qty_14d,
    lead_time_days,
    days_of_supply,
    expected_days_of_supply,
    risk_level
FROM mart_stock_risk;

-- Удаляем представление pbi_replenishment_recommendation, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS pbi_replenishment_recommendation;

-- Создаем рекомендации по пополнению запасов для Power BI.
CREATE VIEW pbi_replenishment_recommendation AS
SELECT
    snapshot_date AS date_key,
    store_id,
    product_id,
    stock_qty,
    incoming_qty,
    expected_available_qty,
    avg_daily_demand_14d,
    lead_time_days,
    days_of_supply,
    expected_days_of_supply,
    risk_level,
    review_period_days,
    safety_days,
    target_cover_days,
    target_stock_qty,
    recommended_qty,
    estimated_order_cost,
    priority
FROM mart_replenishment_recommendation;