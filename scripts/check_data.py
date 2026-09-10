import sqlite3
import pandas as pd
from pathlib import Path

# Путь к базе данных независимо от того, откуда запускается скрипт
BASE_DIR = Path(__file__).resolve().parents[1]
DB_PATH = BASE_DIR / "data" / "inventory.db"


def print_section(title: str):
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)


def run_query(conn, query: str) -> pd.DataFrame:
    return pd.read_sql(query, conn)


def main():
    if not DB_PATH.exists():
        raise SystemExit(
            f"❌ Файл базы данных не найден:\n{DB_PATH}\n"
            "Сначала запусти скрипт генерации: python scripts/generate_data.py"
        )

    conn = sqlite3.connect(DB_PATH)

    # ------------------------------------------------------------------
    # 1. Проверка количества строк в таблицах
    # ------------------------------------------------------------------
    print_section("1. Количество строк в таблицах")

    query_row_counts = """
        SELECT 'dim_stores' AS table_name, COUNT(*) AS row_count
        FROM dim_stores

        UNION ALL

        SELECT 'dim_products' AS table_name, COUNT(*) AS row_count
        FROM dim_products

        UNION ALL

        SELECT 'fact_sales' AS table_name, COUNT(*) AS row_count
        FROM fact_sales

        UNION ALL

        SELECT 'fact_inventory' AS table_name, COUNT(*) AS row_count
        FROM fact_inventory
    """

    df_counts = run_query(conn, query_row_counts)
    print(df_counts.to_string(index=False))

    expected_counts = {
        "dim_stores": 3,
        "dim_products": 20,
        "fact_sales": 5400,
        "fact_inventory": 5400,
    }

    for table_name, expected_rows in expected_counts.items():
        actual_rows = int(
            df_counts.loc[df_counts["table_name"] == table_name, "row_count"].iloc[0]
        )

        if actual_rows == expected_rows:
            print(f"✅ {table_name}: OK, {actual_rows} строк")
        else:
            print(f"❌ {table_name}: ожидалось {expected_rows}, получено {actual_rows}")

    # ------------------------------------------------------------------
    # 2. Проверка отрицательных остатков
    # ------------------------------------------------------------------
    print_section("2. Проверка отрицательных остатков")

    query_negative_stock = """
        SELECT COUNT(*) AS negative_stock_rows
        FROM fact_inventory
        WHERE stock_qty < 0
    """

    df_negative_stock = run_query(conn, query_negative_stock)
    print(df_negative_stock.to_string(index=False))

    negative_stock_rows = int(df_negative_stock["negative_stock_rows"].iloc[0])

    if negative_stock_rows == 0:
        print("✅ Отрицательных остатков нет")
    else:
        print(f"❌ Найдено отрицательных остатков: {negative_stock_rows}")

    # ------------------------------------------------------------------
    # 3. Проверка дефицитов
    # ------------------------------------------------------------------
    print_section("3. Проверка дефицитов (out-of-stock)")

    query_stockouts = """
        SELECT
            COUNT(*) AS total_inventory_days,
            SUM(is_stockout) AS stockout_days,
            ROUND(SUM(is_stockout) * 100.0 / COUNT(*), 2) AS stockout_rate_pct
        FROM fact_inventory
    """

    df_stockouts = run_query(conn, query_stockouts)
    print(df_stockouts.to_string(index=False))

    stockout_rate_pct = float(df_stockouts["stockout_rate_pct"].iloc[0])

    if stockout_rate_pct > 0:
        print("✅ Дефициты присутствуют — это нормально для бизнес-кейса")
    else:
        print("⚠️ Дефицитов нет. Проверь логику генерации данных")

    # ------------------------------------------------------------------
    # 4. Проверка потерянных продаж
    # ------------------------------------------------------------------
    print_section("4. Проверка потерянных продаж")

    query_lost_sales = """
        SELECT
            SUM(qty_sold) AS total_sold,
            SUM(unconstrained_demand) AS total_demand,
            SUM(lost_sales_qty) AS total_lost_sales_qty,
            ROUND(SUM(lost_sales_qty) * 100.0 / SUM(unconstrained_demand), 2) AS lost_demand_pct
        FROM fact_sales
    """

    df_lost_sales = run_query(conn, query_lost_sales)
    print(df_lost_sales.to_string(index=False))

    total_lost_sales_qty = int(df_lost_sales["total_lost_sales_qty"].iloc[0])

    if total_lost_sales_qty > 0:
        print("✅ Потерянные продажи есть — можно считать упущенную выручку")
    else:
        print("⚠️ Потерянных продаж нет. Проверь логику генерации")

    # ------------------------------------------------------------------
    # 5. Проверка продаж по дням
    # ------------------------------------------------------------------
    print_section("5. Пример данных по продажам")

    query_sample_sales = """
        SELECT
            date,
            store_id,
            product_id,
            qty_sold,
            revenue,
            unconstrained_demand,
            lost_sales_qty
        FROM fact_sales
        WHERE lost_sales_qty > 0
        ORDER BY lost_sales_qty DESC
        LIMIT 10
    """

    df_sample_sales = run_query(conn, query_sample_sales)
    print(df_sample_sales.to_string(index=False))

    conn.close()

    print("\n✅ Проверка данных завершена")


if __name__ == "__main__":
    main()