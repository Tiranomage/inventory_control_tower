-- Проверяем количество строк в широкой таблице ежедневных продаж для DataLens. Ожидаем 5400 строк.
SELECT COUNT(*) AS dl_fact_daily_rows
FROM dl_fact_daily_wide;

-- Проверяем количество строк в широкой таблице ежедневных показателей по магазинам. Ожидаем 270 строк.
SELECT COUNT(*) AS dl_store_daily_rows
FROM dl_store_daily_wide;

-- Проверяем количество строк в широкой таблице показателей по товарам. Ожидаем 20 строк.
SELECT COUNT(*) AS dl_product_kpi_rows
FROM dl_product_kpi_wide;

-- Проверяем количество строк в широкой таблице риска запасов. Ожидаем 60 строк.
SELECT COUNT(*) AS dl_stock_risk_rows
FROM dl_stock_risk_wide;

-- Проверяем количество строк в широкой таблице рекомендаций по пополнению. Количество зависит от состояния запасов.
SELECT COUNT(*) AS dl_replenishment_rows
FROM dl_replenishment_wide;

-- Проверяем, что в таблице ежедневных продаж нет строк без названия магазина. Ожидаем 0 строк.
SELECT COUNT(*) AS missing_store_names
FROM dl_fact_daily_wide
WHERE store_name IS NULL;

-- Проверяем, что в таблице ежедневных продаж нет строк без названия товара. Ожидаем 0 строк.
SELECT COUNT(*) AS missing_product_names
FROM dl_fact_daily_wide
WHERE product_name IS NULL;

-- Проверяем, что в таблице ежедневных продаж нет строк без даты. Ожидаем 0 строк.
SELECT COUNT(*) AS missing_report_dates
FROM dl_fact_daily_wide
WHERE report_date IS NULL;

-- Проверяем, что в таблице риска запасов нет строк без русского названия риска. Ожидаем 0 строк.
SELECT COUNT(*) AS missing_risk_labels
FROM dl_stock_risk_wide
WHERE risk_level_ru IS NULL;

-- Проверяем, что в таблице рекомендаций нет отрицательного объема заказа. Ожидаем 0 строк.
SELECT COUNT(*) AS negative_recommended_qty
FROM dl_replenishment_wide
WHERE recommended_qty < 0;