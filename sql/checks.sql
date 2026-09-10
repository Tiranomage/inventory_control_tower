SELECT 'dim_stores' AS table_name, COUNT(*) AS row_count
FROM dim_stores
UNION ALL
SELECT 'dim_products', COUNT(*)
FROM dim_products
UNION ALL
SELECT 'fact_sales', COUNT(*)
FROM fact_sales
UNION ALL
SELECT 'fact_inventory', COUNT(*)
FROM fact_inventory;


-- 2. Отрицательные остатки
SELECT COUNT(*) AS negative_stock_rows
FROM fact_inventory
WHERE stock_qty < 0;


-- 3. Дефициты
SELECT
    COUNT(*) AS total_inventory_days,
    SUM(is_stockout) AS stockout_days,
    ROUND(SUM(is_stockout) * 100.0 / COUNT(*), 2) AS stockout_rate_pct
FROM fact_inventory;


-- 4. Потерянные продажи
SELECT
    SUM(qty_sold) AS total_sold,
    SUM(unconstrained_demand) AS total_demand,
    SUM(lost_sales_qty) AS total_lost_sales_qty,
    ROUND(SUM(lost_sales_qty) * 100.0 / SUM(unconstrained_demand), 2) AS lost_demand_pct
FROM fact_sales;