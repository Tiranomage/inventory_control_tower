-- Проверяем количество дат в календаре. Ожидаем 90 дат, так как история сгенерирована на 90 дней.
SELECT COUNT(*) AS date_rows
FROM pbi_dim_date;

-- Проверяем количество магазинов в справочнике магазинов. Ожидаем 3 магазина.
SELECT COUNT(*) AS store_rows
FROM pbi_dim_store;

-- Проверяем количество товаров в справочнике товаров. Ожидаем 20 товаров.
SELECT COUNT(*) AS product_rows
FROM pbi_dim_product;

-- Проверяем количество строк в ежедневном факте. Ожидаем 5400 строк: 3 магазина, 20 товаров, 90 дней.
SELECT COUNT(*) AS fact_daily_rows
FROM pbi_fact_daily;

-- Проверяем количество строк в ежедневных показателях по магазинам. Ожидаем 270 строк: 3 магазина и 90 дней.
SELECT COUNT(*) AS store_daily_kpi_rows
FROM pbi_fact_store_daily_kpi;

-- Проверяем количество строк в показателях по товарам. Ожидаем 20 строк.
SELECT COUNT(*) AS product_kpi_rows
FROM pbi_fact_product_kpi;

-- Проверяем количество строк в срезе риска запасов. Ожидаем 60 строк: 3 магазина и 20 товаров.
SELECT COUNT(*) AS stock_risk_rows
FROM pbi_snapshot_stock_risk;

-- Проверяем количество рекомендаций по пополнению. Количество может быть разным в зависимости от состояния запасов.
SELECT COUNT(*) AS replenishment_rows
FROM pbi_replenishment_recommendation;

-- Проверяем, что в ежедневном факте нет дат, которых нет в календаре. Ожидаем 0 строк.
SELECT COUNT(*) AS orphan_fact_daily_dates
FROM pbi_fact_daily AS f
LEFT JOIN pbi_dim_date AS d
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;

-- Проверяем, что в ежедневном факте нет магазинов, которых нет в справочнике магазинов. Ожидаем 0 строк.
SELECT COUNT(*) AS orphan_fact_daily_stores
FROM pbi_fact_daily AS f
LEFT JOIN pbi_dim_store AS s
    ON f.store_id = s.store_id
WHERE s.store_id IS NULL;

-- Проверяем, что в ежедневном факте нет товаров, которых нет в справочнике товаров. Ожидаем 0 строк.
SELECT COUNT(*) AS orphan_fact_daily_products
FROM pbi_fact_daily AS f
LEFT JOIN pbi_dim_product AS p
    ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Проверяем, что в срезе риска запасов нет дат, которых нет в календаре. Ожидаем 0 строк.
SELECT COUNT(*) AS orphan_stock_risk_dates
FROM pbi_snapshot_stock_risk AS r
LEFT JOIN pbi_dim_date AS d
    ON r.date_key = d.date_key
WHERE d.date_key IS NULL;

-- Проверяем, что в рекомендациях по пополнению нет отрицательного объема заказа. Ожидаем 0 строк.
SELECT COUNT(*) AS negative_replenishment_qty
FROM pbi_replenishment_recommendation
WHERE recommended_qty < 0;