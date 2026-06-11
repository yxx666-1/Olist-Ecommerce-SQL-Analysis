import pandas as pd
from sqlalchemy import create_engine

# 数据库配置
user = "root"
pwd = "123456"
host = "127.0.0.1"
port = 3306
db_name = "olist_ecommerce"

# 你的CSV文件夹路径
csv_folder = r"F:\桌面\新建文件夹"

# 连接MySQL库
engine = create_engine(f"mysql+pymysql://{user}:{pwd}@{host}:{port}/{db_name}")

# 8个标准csv文件名列表
file_names = [
    "olist_customers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv"
]

# 循环批量导入每张表
for file in file_names:
    table_name = file.replace("_dataset.csv", "")
    full_file_path = f"{csv_folder}\\{file}"
    df = pd.read_csv(full_file_path)
    df.to_sql(name=table_name, con=engine, if_exists="replace", index=False, chunksize=10000)
    print(f"✅ {table_name} 导入完成，数据行数：{len(df)}")