import pandas as pd
import numpy as np
import sqlite3
import os
from datetime import datetime, timedelta

# --- 1. Настройки и параметры ---
np.random.seed(42)
NUM_STORES = 3
NUM_PRODUCTS = 20
DAYS_HISTORY = 90
DB_PATH = 'data/inventory.db'

# Создаем папку data, если её нет
os.makedirs('data', exist_ok=True)

# --- 2. Генерация измерений (Dimensions) ---
# Магазины
stores = pd.DataFrame({
    'store_id': [f'ST{str(i).zfill(3)}' for i in range(1, NUM_STORES + 1)],
    'store_name': [f'Market_{i}' for i in range(1, NUM_STORES + 1)],
    'city': np.random.choice(['Moscow', 'St Petersburg', 'Kazan'], NUM_STORES)
})

# Товары
categories = ['Beverages', 'Snacks', 'Dairy', 'Household']
products = pd.DataFrame({
    'product_id': [f'PR{str(i).zfill(3)}' for i in range(1, NUM_PRODUCTS + 1)],
    'product_name': [f'Product_{i}' for i in range(1, NUM_PRODUCTS + 1)],
    'category': np.random.choice(categories, NUM_PRODUCTS),
    'cost_price': np.random.uniform(20, 150, NUM_PRODUCTS).round(2),
    'base_demand': np.random.randint(5, 30, NUM_PRODUCTS), # Базовый дневной спрос
    'lead_time_days': np.random.choice([3, 5, 7, 10], NUM_PRODUCTS) # Срок поставки
})
products['sale_price'] = (products['cost_price'] * np.random.uniform(1.3, 1.8, NUM_PRODUCTS)).round(2)

# --- 3. Симуляция фактов (Продажи и Остатки) ---
start_date = datetime.today() - timedelta(days=DAYS_HISTORY)
dates = pd.date_range(start=start_date, periods=DAYS_HISTORY, freq='D')

sales_records = []
inventory_records = []

print("Начинаем симуляцию продаж и остатков...")

for _, store in stores.iterrows():
    for _, product in products.iterrows():
        
        # Начальный остаток (берем с запасом на пару недель)
        current_stock = int(product['base_demand'] * 14) 
        reorder_point = int(product['base_demand'] * product['lead_time_days'] * 1.2) # Точка заказа
        order_qty = int(product['base_demand'] * 14) # Объем заказа
        
        # Флаг: едет ли сейчас поставка
        incoming_stock = 0
        days_until_delivery = 0

        for date in dates:
            day_of_week = date.dayofweek
            
            # Множитель выходных (в сб/вс продаем на 40% больше)
            weekend_multiplier = 1.4 if day_of_week >= 5 else 1.0
            
            # Генерация спроса (распределение Пуассона + шум)
            expected_demand = product['base_demand'] * weekend_multiplier
            unconstrained_demand = max(0, int(np.random.poisson(expected_demand)))
            
            # Приход товара, если он был в пути
            if days_until_delivery == 0 and incoming_stock > 0:
                current_stock += incoming_stock
                incoming_stock = 0
            
            # Фактические продажи (не могут превышать остаток)
            actual_sales = min(unconstrained_demand, current_stock)
            current_stock -= actual_sales
            
            # Фиксация факта дефицита (спрос был, а товара не хватило)
            lost_sales_qty = unconstrained_demand - actual_sales
            
            # Логика автозаказа (упрощенная)
            if days_until_delivery > 0:
                days_until_delivery -= 1
                
            if current_stock <= reorder_point and incoming_stock == 0:
                # Делаем заказ
                incoming_stock = order_qty
                days_until_delivery = product['lead_time_days']

            # Сохраняем продажи
            sales_records.append({
                'date': date.strftime('%Y-%m-%d'),
                'store_id': store['store_id'],
                'product_id': product['product_id'],
                'qty_sold': actual_sales,
                'revenue': round(actual_sales * product['sale_price'], 2),
                'unconstrained_demand': unconstrained_demand, # Реальный спрос (для расчета потерь)
                'lost_sales_qty': lost_sales_qty
            })
            
            # Сохраняем остаток на конец дня
            inventory_records.append({
                'date': date.strftime('%Y-%m-%d'),
                'store_id': store['store_id'],
                'product_id': product['product_id'],
                'stock_qty': current_stock,
                'incoming_qty': incoming_stock if days_until_delivery == 1 else 0, # Ожидаем завтра
                'is_stockout': 1 if current_stock == 0 else 0
            })

df_sales = pd.DataFrame(sales_records)
df_inventory = pd.DataFrame(inventory_records)

print(f"Сгенерировано {len(df_sales)} строк продаж и {len(df_inventory)} строк остатков.")

# --- 4. Загрузка в SQLite ---
print(f"Сохраняем в базу данных: {DB_PATH}...")

# Удаляем старую БД, если есть, чтобы не было дублей при повторном запуске
if os.path.exists(DB_PATH):
    os.remove(DB_PATH)

conn = sqlite3.connect(DB_PATH)

stores.to_sql('dim_stores', conn, index=False, if_exists='replace')
products.to_sql('dim_products', conn, index=False, if_exists='replace')
df_sales.to_sql('fact_sales', conn, index=False, if_exists='replace')
df_inventory.to_sql('fact_inventory', conn, index=False, if_exists='replace')

conn.close()
print("Данные успешно сгенерированы и загружены в SQLite!")