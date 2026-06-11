import pandas as pd
import matplotlib.pyplot as plt
from sqlalchemy import create_engine

# 解决中文乱码
plt.rcParams['font.sans-serif'] = ['SimHei']
plt.rcParams['axes.unicode_minus'] = False

# 数据库连接
engine = create_engine("mysql+pymysql://root:123456@127.0.0.1:3306/olist_ecommerce")

# 1. 月度订单营收趋势图
df_month = pd.read_sql("""
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
COUNT(DISTINCT o.order_id) AS order_count,
ROUND(SUM(oi.price + oi.freight_value),2) AS revenue
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month ORDER BY month;
""", engine)

fig, ax1 = plt.subplots(figsize=(14,6))
ax1.plot(df_month['month'], df_month['order_count'], marker='o', color='#2E86AB', label='订单数量')
ax1.set_xlabel('月份')
ax1.set_ylabel('订单数', color='#2E86AB')
ax1.tick_params(axis='x', rotation=45)

ax2 = ax1.twinx()
ax2.plot(df_month['month'], df_month['revenue'], marker='s', color='#C73E1D', label='营收金额')
ax2.set_ylabel('营收', color='#C73E1D')
plt.title('Olist平台月度订单量&营收趋势')
fig.legend(loc="upper left")
plt.tight_layout()
plt.savefig('月度趋势图.png', dpi=300)
plt.close()

# 2. 商品销量TOP10横向柱状图
df_cat = pd.read_sql("""
SELECT p.product_category_name category_name,
COUNT(oi.order_item_id) sales_volume
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id=p.product_id
GROUP BY category_name ORDER BY sales_volume DESC LIMIT 10;
""",engine)

plt.figure(figsize=(12,7))
plt.barh(df_cat['category_name'], df_cat['sales_volume'], color='#F18F01')
plt.gca().invert_yaxis()
plt.title('商品类目销量TOP10')
plt.xlabel('销量')
plt.tight_layout()
plt.savefig('类目销量TOP10.png', dpi=300)
plt.close()

# 3. RFM用户分层营收占比饼图
df_rfm = pd.read_sql("""
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-09-01', MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price + oi.freight_value) AS monetary
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_score AS (
    SELECT
        customer_unique_id,
        monetary,
        NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN '重要价值用户'
        WHEN r_score >= 4 AND f_score < 4 AND m_score >= 4 THEN '重要发展用户'
        WHEN r_score < 4 AND f_score >= 4 AND m_score >= 4 THEN '重要保持用户'
        WHEN r_score < 4 AND f_score < 4 AND m_score >= 4 THEN '重要挽留用户'
        ELSE '其他用户'
    END AS user_type,
    SUM(monetary) AS total_revenue
FROM rfm_score
GROUP BY user_type;
""",engine)

plt.figure(figsize=(10,10))
plt.pie(df_rfm['total_revenue'], labels=df_rfm['user_type'], autopct='%1.1f%%', startangle=90)
plt.title('各用户分层营收占比')
plt.tight_layout()
plt.savefig('RFM营收饼图.png', dpi=300)
plt.close()

print("三张可视化图表全部生成完毕！")