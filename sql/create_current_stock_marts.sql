-- Удаляем представление mart_last_date, если оно уже существовало. Это нужно, чтобы скрипт можно было запускать повторно без ошибок.
DROP VIEW IF EXISTS mart_last_date;

-- Создаем служебное представление mart_last_date. Оно возвращает последнюю дату в продажах. Эта дата будет использоваться как точка среза для анализа текущих остатков.
CREATE VIEW mart_last_date AS
SELECT MAX(date) AS last_date
FROM fact_sales;

-- Удаляем представление mart_sales_velocity, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS mart_sales_velocity;

-- Создаем витрину скорости продаж за последние 14 дней. Для оценки спроса используется unconstrained_demand, чтобы дефицит не занижал реальную потребность.
CREATE VIEW mart_sales_velocity AS
SELECT
    s.store_id,
    s.product_id,
    ROUND(AVG(s.unconstrained_demand), 2) AS avg_daily_demand_14d,
    ROUND(AVG(s.qty_sold), 2) AS avg_daily_sales_14d,
    ROUND(SUM(s.qty_sold), 0) AS sales_qty_14d,
    ROUND(SUM(s.unconstrained_demand), 0) AS demand_qty_14d,
    ROUND(SUM(s.lost_sales_qty), 0) AS lost_sales_qty_14d,
    ROUND(SUM(i.is_stockout), 0) AS stockout_days_14d
FROM fact_sales AS s
LEFT JOIN fact_inventory AS i
    ON s.date = i.date
   AND s.store_id = i.store_id
   AND s.product_id = i.product_id
CROSS JOIN mart_last_date AS l
WHERE s.date >= date(l.last_date, '-13 days')
GROUP BY
    s.store_id,
    s.product_id;

-- Удаляем представление mart_current_stock, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS mart_current_stock;

-- Создаем витрину текущих остатков на последнюю доступную дату. Показывает остаток, входящие поставки, стоимость запасов и базовые справочники.
CREATE VIEW mart_current_stock AS
SELECT
    i.date AS snapshot_date,
    i.store_id,
    st.store_name,
    st.city,
    i.product_id,
    p.product_name,
    p.category,
    i.stock_qty,
    i.incoming_qty,
    i.stock_qty + i.incoming_qty AS expected_available_qty,
    p.cost_price,
    p.sale_price,
    p.lead_time_days,
    ROUND(i.stock_qty * p.cost_price, 2) AS stock_cost_value,
    ROUND(i.stock_qty * p.sale_price, 2) AS stock_retail_value,
    CASE
        WHEN i.stock_qty = 0 THEN 1
        ELSE 0
    END AS is_stockout_now
FROM fact_inventory AS i
CROSS JOIN mart_last_date AS l
LEFT JOIN dim_stores AS st
    ON i.store_id = st.store_id
LEFT JOIN dim_products AS p
    ON i.product_id = p.product_id
WHERE i.date = l.last_date;

-- Удаляем представление mart_stock_risk, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS mart_stock_risk;

-- Создаем витрину риска дефицита. Она соединяет текущие остатки и скорость спроса, считает дни запаса и уровень риска.
CREATE VIEW mart_stock_risk AS
SELECT
    c.snapshot_date,
    c.store_id,
    c.store_name,
    c.city,
    c.product_id,
    c.product_name,
    c.category,
    c.stock_qty,
    c.incoming_qty,
    c.expected_available_qty,
    COALESCE(v.avg_daily_demand_14d, 0) AS avg_daily_demand_14d,
    COALESCE(v.avg_daily_sales_14d, 0) AS avg_daily_sales_14d,
    COALESCE(v.stockout_days_14d, 0) AS stockout_days_14d,
    COALESCE(v.lost_sales_qty_14d, 0) AS lost_sales_qty_14d,
    c.lead_time_days,
    CASE
        WHEN COALESCE(v.avg_daily_demand_14d, 0) = 0 THEN NULL
        ELSE ROUND(c.stock_qty / v.avg_daily_demand_14d, 1)
    END AS days_of_supply,
    CASE
        WHEN COALESCE(v.avg_daily_demand_14d, 0) = 0 THEN NULL
        ELSE ROUND(c.expected_available_qty / v.avg_daily_demand_14d, 1)
    END AS expected_days_of_supply,
    CASE
        WHEN COALESCE(v.avg_daily_demand_14d, 0) = 0 THEN 'no_demand'
        WHEN c.stock_qty = 0 THEN 'stockout'
        WHEN c.stock_qty / v.avg_daily_demand_14d <= c.lead_time_days THEN 'critical'
        WHEN c.stock_qty / v.avg_daily_demand_14d <= c.lead_time_days + 3 THEN 'high'
        WHEN c.stock_qty / v.avg_daily_demand_14d <= c.lead_time_days + 7 THEN 'medium'
        ELSE 'ok'
    END AS risk_level
FROM mart_current_stock AS c
LEFT JOIN mart_sales_velocity AS v
    ON c.store_id = v.store_id
   AND c.product_id = v.product_id;

-- Удаляем представление mart_replenishment_recommendation, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS mart_replenishment_recommendation;

-- Создаем витрину рекомендаций по пополнению. Она считает целевой запас, рекомендуемый объем заказа, примерную стоимость заказа и приоритет.
CREATE VIEW mart_replenishment_recommendation AS
WITH base AS (
    SELECT
        r.snapshot_date,
        r.store_id,
        r.store_name,
        r.city,
        r.product_id,
        r.product_name,
        r.category,
        r.stock_qty,
        r.incoming_qty,
        r.expected_available_qty,
        r.avg_daily_demand_14d,
        r.lead_time_days,
        r.days_of_supply,
        r.expected_days_of_supply,
        r.risk_level,
        p.cost_price,
        7 AS review_period_days,
        2 AS safety_days,
        r.lead_time_days + 7 + 2 AS target_cover_days
    FROM mart_stock_risk AS r
    LEFT JOIN dim_products AS p
        ON r.product_id = p.product_id
    WHERE r.avg_daily_demand_14d > 0
), calc AS (
    SELECT
        base.snapshot_date,
        base.store_id,
        base.store_name,
        base.city,
        base.product_id,
        base.product_name,
        base.category,
        base.stock_qty,
        base.incoming_qty,
        base.expected_available_qty,
        base.avg_daily_demand_14d,
        base.lead_time_days,
        base.days_of_supply,
        base.expected_days_of_supply,
        base.risk_level,
        base.review_period_days,
        base.safety_days,
        base.target_cover_days,
        base.cost_price,
        ROUND(base.avg_daily_demand_14d * base.target_cover_days, 0) AS target_stock_qty,
        MAX(0, ROUND(base.avg_daily_demand_14d * base.target_cover_days, 0) - base.expected_available_qty) AS recommended_qty
    FROM base
)
SELECT
    calc.snapshot_date,
    calc.store_id,
    calc.store_name,
    calc.city,
    calc.product_id,
    calc.product_name,
    calc.category,
    calc.stock_qty,
    calc.incoming_qty,
    calc.expected_available_qty,
    calc.avg_daily_demand_14d,
    calc.lead_time_days,
    calc.days_of_supply,
    calc.expected_days_of_supply,
    calc.risk_level,
    calc.review_period_days,
    calc.safety_days,
    calc.target_cover_days,
    calc.target_stock_qty,
    calc.recommended_qty,
    ROUND(calc.recommended_qty * calc.cost_price, 2) AS estimated_order_cost,
    CASE
        WHEN calc.risk_level = 'stockout' THEN 1
        WHEN calc.risk_level = 'critical' THEN 2
        WHEN calc.risk_level = 'high' THEN 3
        WHEN calc.risk_level = 'medium' THEN 4
        ELSE 5
    END AS priority
FROM calc
WHERE calc.recommended_qty > 0;