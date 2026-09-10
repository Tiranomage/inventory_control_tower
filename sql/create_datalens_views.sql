-- Удаляем представление dl_fact_daily_wide, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS dl_fact_daily_wide;

-- Создаем широкую таблицу ежедневных продаж для DataLens. В одну таблицу добавлены атрибуты даты, магазина и товара, чтобы упростить импорт и уменьшить потребность в связях.
CREATE VIEW dl_fact_daily_wide AS
SELECT
    f.date_key AS report_date,
    d.year,
    d.month_number,
    d.year_month,
    d.month_start,
    d.day_of_month,
    d.weekday_name,
    d.is_weekend,
    s.store_id,
    s.store_name,
    s.city,
    p.product_id,
    p.product_name,
    p.category,
    f.qty_sold,
    f.revenue,
    f.cogs,
    f.gross_profit,
    f.unconstrained_demand,
    f.lost_sales_qty,
    f.lost_revenue,
    f.potential_revenue,
    f.service_level,
    f.stock_qty,
    f.incoming_qty,
    f.is_stockout,
    f.in_stock_flag
FROM pbi_fact_daily AS f
LEFT JOIN pbi_dim_date AS d
    ON f.date_key = d.date_key
LEFT JOIN pbi_dim_store AS s
    ON f.store_id = s.store_id
LEFT JOIN pbi_dim_product AS p
    ON f.product_id = p.product_id;

-- Удаляем представление dl_store_daily_wide, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS dl_store_daily_wide;

-- Создаем широкую таблицу ежедневных показателей по магазинам для DataLens.
CREATE VIEW dl_store_daily_wide AS
SELECT
    k.date_key AS report_date,
    d.year,
    d.month_number,
    d.year_month,
    d.month_start,
    s.store_id,
    s.store_name,
    s.city,
    k.lines_count,
    k.qty_sold,
    k.revenue,
    k.gross_profit,
    k.lost_sales_qty,
    k.lost_revenue,
    k.potential_revenue,
    k.stock_qty,
    k.incoming_qty,
    k.stockout_lines,
    k.stockout_rate_pct,
    k.revenue_capture_pct
FROM pbi_fact_store_daily_kpi AS k
LEFT JOIN pbi_dim_date AS d
    ON k.date_key = d.date_key
LEFT JOIN pbi_dim_store AS s
    ON k.store_id = s.store_id;

-- Удаляем представление dl_product_kpi_wide, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS dl_product_kpi_wide;

-- Создаем широкую таблицу показателей по товарам для DataLens.
CREATE VIEW dl_product_kpi_wide AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.cost_price,
    p.sale_price,
    p.lead_time_days,
    k.total_qty_sold,
    k.total_revenue,
    k.total_gross_profit,
    k.total_lost_sales_qty,
    k.total_lost_revenue,
    k.total_potential_revenue,
    k.stockout_days,
    k.lost_revenue_pct
FROM pbi_fact_product_kpi AS k
LEFT JOIN pbi_dim_product AS p
    ON k.product_id = p.product_id;

-- Удаляем представление dl_stock_risk_wide, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS dl_stock_risk_wide;

-- Создаем широкую таблицу текущего риска дефицита для DataLens. Добавлены русские статусы риска и порядок сортировки.
CREATE VIEW dl_stock_risk_wide AS
SELECT
    r.date_key AS snapshot_date,
    d.year,
    d.month_number,
    d.year_month,
    d.month_start,
    s.store_id,
    s.store_name,
    s.city,
    p.product_id,
    p.product_name,
    p.category,
    r.stock_qty,
    r.incoming_qty,
    r.expected_available_qty,
    r.avg_daily_demand_14d,
    r.avg_daily_sales_14d,
    r.stockout_days_14d,
    r.lost_sales_qty_14d,
    r.lead_time_days,
    r.days_of_supply,
    r.expected_days_of_supply,
    r.risk_level,
    CASE r.risk_level
        WHEN 'stockout' THEN 'Дефицит'
        WHEN 'critical' THEN 'Критично'
        WHEN 'high' THEN 'Высокий'
        WHEN 'medium' THEN 'Средний'
        WHEN 'ok' THEN 'Норма'
        ELSE 'Нет спроса'
    END AS risk_level_ru,
    CASE r.risk_level
        WHEN 'stockout' THEN 1
        WHEN 'critical' THEN 2
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 4
        WHEN 'ok' THEN 5
        ELSE 6
    END AS risk_sort
FROM pbi_snapshot_stock_risk AS r
LEFT JOIN pbi_dim_date AS d
    ON r.date_key = d.date_key
LEFT JOIN pbi_dim_store AS s
    ON r.store_id = s.store_id
LEFT JOIN pbi_dim_product AS p
    ON r.product_id = p.product_id;

-- Удаляем представление dl_replenishment_wide, если оно уже существовало. Это нужно для повторного запуска скрипта.
DROP VIEW IF EXISTS dl_replenishment_wide;

-- Создаем широкую таблицу рекомендаций по пополнению для DataLens. Добавлены русские статусы риска и приоритета.
CREATE VIEW dl_replenishment_wide AS
SELECT
    r.date_key AS snapshot_date,
    d.year,
    d.month_number,
    d.year_month,
    d.month_start,
    s.store_id,
    s.store_name,
    s.city,
    p.product_id,
    p.product_name,
    p.category,
    r.stock_qty,
    r.incoming_qty,
    r.expected_available_qty,
    r.avg_daily_demand_14d,
    r.lead_time_days,
    r.days_of_supply,
    r.expected_days_of_supply,
    r.risk_level,
    CASE r.risk_level
        WHEN 'stockout' THEN 'Дефицит'
        WHEN 'critical' THEN 'Критично'
        WHEN 'high' THEN 'Высокий'
        WHEN 'medium' THEN 'Средний'
        ELSE 'Норма'
    END AS risk_level_ru,
    r.review_period_days,
    r.safety_days,
    r.target_cover_days,
    r.target_stock_qty,
    r.recommended_qty,
    r.estimated_order_cost,
    r.priority,
    CASE r.priority
        WHEN 1 THEN 'Срочно'
        WHEN 2 THEN 'Высокий'
        WHEN 3 THEN 'Средний'
        WHEN 4 THEN 'Низкий'
        ELSE 'Позже'
    END AS priority_label
FROM pbi_replenishment_recommendation AS r
LEFT JOIN pbi_dim_date AS d
    ON r.date_key = d.date_key
LEFT JOIN pbi_dim_store AS s
    ON r.store_id = s.store_id
LEFT JOIN pbi_dim_product AS p
    ON r.product_id = p.product_id;