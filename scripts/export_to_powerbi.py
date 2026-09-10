import os
import sqlite3
import pandas as pd

DB_PATH = "data/inventory.db"
OUTPUT_DIR = "data/powerbi"

VIEWS = [
    "pbi_dim_date",
    "pbi_dim_store",
    "pbi_dim_product",
    "pbi_fact_daily",
    "pbi_fact_store_daily_kpi",
    "pbi_fact_product_kpi",
    "pbi_snapshot_stock_risk",
    "pbi_replenishment_recommendation"
]

def main():
    if not os.path.exists(DB_PATH):
        raise FileNotFoundError(f"База данных не найдена: {DB_PATH}")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    conn = sqlite3.connect(DB_PATH)

    for view_name in VIEWS:
        query = f"SELECT * FROM {view_name}"
        df = pd.read_sql_query(query, conn)

        output_path = os.path.join(OUTPUT_DIR, f"{view_name}.csv")
        df.to_csv(output_path, index=False, encoding="utf-8-sig")

        print(f"Выгружено: {view_name} | строк: {len(df)} | файл: {output_path}")

    conn.close()
    print("Экспорт в CSV завершен.")

if __name__ == "__main__":
    main()