SELECT COUNT(*) AS mart_rows
FROM mart_daily_performance;

SELECT COUNT(DISTINCT date || '|' || store_id || '|' || product_id) AS unique_keys
FROM mart_daily_performance;

SELECT COUNT(*) AS missing_inventory_rows
FROM mart_daily_performance
WHERE stock_qty IS NULL;

SELECT COUNT(*) AS bad_rows
FROM mart_daily_performance
WHERE revenue < 0
   OR lost_revenue < 0
   OR qty_sold < 0
   OR lost_sales_qty < 0;

SELECT COUNT(*) AS bad_potential_revenue_rows
FROM mart_daily_performance
WHERE potential_revenue < revenue;

SELECT
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(lost_revenue), 2) AS total_lost_revenue,
    ROUND(SUM(potential_revenue), 2) AS total_potential_revenue,
    ROUND(SUM(lost_revenue) * 100.0 / NULLIF(SUM(potential_revenue), 0), 2) AS lost_revenue_pct
FROM mart_daily_performance;

SELECT
    date,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(lost_revenue), 2) AS lost_revenue,
    ROUND(SUM(potential_revenue), 2) AS potential_revenue,
    SUM(stock_qty) AS stock_qty,
    SUM(is_stockout) AS stockout_lines
FROM mart_daily_performance
GROUP BY date
ORDER BY date DESC
LIMIT 14;

SELECT
    date,
    store_name,
    product_name,
    category,
    qty_sold,
    unconstrained_demand,
    lost_sales_qty,
    stock_qty,
    ROUND(lost_revenue, 2) AS lost_revenue
FROM mart_daily_performance
WHERE lost_sales_qty > 0
ORDER BY lost_revenue DESC
LIMIT 20;

SELECT COUNT(*) AS store_kpi_rows
FROM mart_store_daily_kpi;

SELECT
    date,
    store_name,
    revenue,
    lost_revenue,
    potential_revenue,
    stockout_rate_pct,
    revenue_capture_pct
FROM mart_store_daily_kpi
ORDER BY date DESC, lost_revenue DESC
LIMIT 30;

SELECT
    store_name,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(lost_revenue), 2) AS total_lost_revenue,
    ROUND(SUM(potential_revenue), 2) AS total_potential_revenue,
    ROUND(AVG(stockout_rate_pct), 2) AS avg_stockout_rate_pct,
    ROUND(
        SUM(revenue) * 100.0 / NULLIF(SUM(potential_revenue), 0),
        2
    ) AS revenue_capture_pct
FROM mart_store_daily_kpi
GROUP BY store_name
ORDER BY total_lost_revenue DESC;

SELECT COUNT(*) AS product_kpi_rows
FROM mart_product_kpi;

SELECT
    product_name,
    category,
    total_qty_sold,
    total_revenue,
    total_lost_sales_qty,
    total_lost_revenue,
    stockout_days,
    lost_revenue_pct
FROM mart_product_kpi
ORDER BY total_lost_revenue DESC
LIMIT 10;

SELECT
    product_name,
    category,
    total_qty_sold,
    total_revenue,
    total_gross_profit,
    total_lost_revenue
FROM mart_product_kpi
ORDER BY total_revenue DESC
LIMIT 10;

SELECT
    product_name,
    category,
    stockout_days,
    total_lost_sales_qty,
    total_lost_revenue
FROM mart_product_kpi
WHERE stockout_days > 0
ORDER BY stockout_days DESC, total_lost_revenue DESC
LIMIT 10;
