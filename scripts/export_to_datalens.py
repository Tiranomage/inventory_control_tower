import os
import sqlite3
import pandas as pd

DB_PATH = "data/inventory.db"
OUTPUT_DIR = "data/datalens"

VIEWS = [
    "dl_fact_daily_wide",
    "dl_store_daily_wide",
    "dl_product_kpi_wide",
    "dl_stock_risk_wide",
    "dl_replenishment_wide"
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

        df.to_csv(
            output_path,
            index=False,
            encoding="utf-8",
            date_format="%Y-%m-%d"
        )

        print(f"Выгружено: {view_name} | строк: {len(df)} | файл: {output_path}")

    conn.close()
    print("Экспорт CSV для DataLens завершен.")

if __name__ == "__main__":
    main()