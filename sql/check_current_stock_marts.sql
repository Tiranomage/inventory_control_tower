-- Проверяем последнюю дату в данных. Запрос должен вернуть одну дату, которая является концом доступной истории.
SELECT last_date
FROM mart_last_date;

-- Проверяем количество строк в витрине скорости продаж. Ожидаем 60 строк: 3 магазина умножить на 20 товаров.
SELECT COUNT(*) AS velocity_rows
FROM mart_sales_velocity;

-- Проверяем количество строк в витрине текущих остатков. Ожидаем 60 строк: 3 магазина умножить на 20 товаров.
SELECT COUNT(*) AS current_stock_rows
FROM mart_current_stock;

-- Проверяем количество строк в витрине риска. Ожидаем 60 строк: 3 магазина умножить на 20 товаров.
SELECT COUNT(*) AS stock_risk_rows
FROM mart_stock_risk;

-- Проверяем распределение товаров по уровням риска. Запрос показывает, сколько товаров находится в каждом статусе.
SELECT
    risk_level,
    COUNT(*) AS items_count
FROM mart_stock_risk
GROUP BY risk_level
ORDER BY items_count DESC;

-- Проверяем товары с наибольшим риском дефицита. Запрос показывает товары в статусе stockout или critical.
SELECT
    store_name,
    product_name,
    category,
    stock_qty,
    incoming_qty,
    avg_daily_demand_14d,
    days_of_supply,
    lead_time_days,
    risk_level
FROM mart_stock_risk
WHERE risk_level IN ('stockout', 'critical')
ORDER BY days_of_supply ASC, stock_qty ASC
LIMIT 20;

-- Проверяем количество рекомендаций по пополнению. Если рекомендаций ноль, значит система считает, что запасов достаточно.
SELECT COUNT(*) AS recommendation_rows
FROM mart_replenishment_recommendation;

-- Проверяем топ рекомендаций по пополнению. Запрос показывает самые приоритетные позиции, которые нужно заказать.
SELECT
    store_name,
    product_name,
    category,
    stock_qty,
    incoming_qty,
    avg_daily_demand_14d,
    lead_time_days,
    target_stock_qty,
    recommended_qty,
    estimated_order_cost,
    priority
FROM mart_replenishment_recommendation
ORDER BY priority ASC, estimated_order_cost DESC
LIMIT 20;

-- Проверяем суммарную стоимость рекомендаций по магазинам. Запрос показывает, сколько денег потенциально нужно на закупку по каждому магазину.
SELECT
    store_name,
    COUNT(*) AS orders_count,
    SUM(recommended_qty) AS total_recommended_qty,
    ROUND(SUM(estimated_order_cost), 2) AS total_estimated_cost
FROM mart_replenishment_recommendation
GROUP BY store_name
ORDER BY total_estimated_cost DESC;

-- Проверяем, что в рекомендациях нет отрицательного объема заказа. Ожидаем 0 строк.
SELECT COUNT(*) AS negative_recommendations
FROM mart_replenishment_recommendation
WHERE recommended_qty < 0;