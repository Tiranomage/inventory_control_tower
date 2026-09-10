SELECT
    date,
    store_id,
    product_id,
    COUNT(*) AS duplicates_count
FROM fact_sales
GROUP BY
    date,
    store_id,
    product_id
HAVING COUNT(*) > 1;

-- Проверка дублей в остатках
SELECT
    date,
    store_id,
    product_id,
    COUNT(*) AS duplicates_count
FROM fact_inventory
GROUP BY
    date,
    store_id,
    product_id
HAVING COUNT(*) > 1;