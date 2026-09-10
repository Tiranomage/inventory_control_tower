DROP VIEW IF EXISTS mart_daily_performance;

CREATE VIEW mart_daily_performance AS
SELECT
    s.date,
    s.store_id,
    st.store_name,
    st.city,
    s.product_id,
    p.product_name,
    p.category,
    s.qty_sold,
    s.revenue,
    s.unconstrained_demand,
    s.lost_sales_qty,
    i.stock_qty,
    i.incoming_qty,
    i.is_stockout,
    p.cost_price,
    p.sale_price,
    p.lead_time_days,
    s.qty_sold * p.cost_price AS cogs,
    s.revenue - (s.qty_sold * p.cost_price) AS gross_profit,
    s.lost_sales_qty * p.sale_price AS lost_revenue,
    (s.qty_sold + s.lost_sales_qty) * p.sale_price AS potential_revenue,
    CASE
        WHEN s.unconstrained_demand > 0
        THEN s.qty_sold * 1.0 / s.unconstrained_demand
        ELSE 1
    END AS service_level,
    CASE
        WHEN i.stock_qty > 0
        THEN 1
        ELSE 0
    END AS in_stock_flag
FROM fact_sales AS s
LEFT JOIN dim_stores AS st
    ON s.store_id = st.store_id
LEFT JOIN dim_products AS p
    ON s.product_id = p.product_id
LEFT JOIN fact_inventory AS i
    ON s.date = i.date
   AND s.store_id = i.store_id
   AND s.product_id = i.product_id;

DROP VIEW IF EXISTS mart_store_daily_kpi;

CREATE VIEW mart_store_daily_kpi AS
SELECT
    date,
    store_id,
    MAX(store_name) AS store_name,
    MAX(city) AS city,
    COUNT(*) AS lines_count,
    SUM(qty_sold) AS qty_sold,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(gross_profit), 2) AS gross_profit,
    SUM(lost_sales_qty) AS lost_sales_qty,
    ROUND(SUM(lost_revenue), 2) AS lost_revenue,
    ROUND(SUM(potential_revenue), 2) AS potential_revenue,
    SUM(stock_qty) AS stock_qty,
    SUM(incoming_qty) AS incoming_qty,
    SUM(is_stockout) AS stockout_lines,
    ROUND(
        SUM(is_stockout) * 100.0 / COUNT(*),
        2
    ) AS stockout_rate_pct,
    ROUND(
        SUM(revenue) * 100.0 / NULLIF(SUM(potential_revenue), 0),
        2
    ) AS revenue_capture_pct
FROM mart_daily_performance
GROUP BY
    date,
    store_id;

DROP VIEW IF EXISTS mart_product_kpi;

CREATE VIEW mart_product_kpi AS
SELECT
    product_id,
    MAX(product_name) AS product_name,
    MAX(category) AS category,
    SUM(qty_sold) AS total_qty_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(gross_profit), 2) AS total_gross_profit,
    SUM(lost_sales_qty) AS total_lost_sales_qty,
    ROUND(SUM(lost_revenue), 2) AS total_lost_revenue,
    ROUND(SUM(potential_revenue), 2) AS total_potential_revenue,
    SUM(is_stockout) AS stockout_days,
    ROUND(
        SUM(lost_revenue) * 100.0 / NULLIF(SUM(potential_revenue), 0),
        2
    ) AS lost_revenue_pct
FROM mart_daily_performance
GROUP BY
    product_id;