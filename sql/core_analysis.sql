-- 1. 有效交付订单总指标
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue,
    COUNT(DISTINCT oi.product_id) AS total_products
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

-- 2. 订单状态分布
SELECT
    order_status,
    COUNT(*) AS count_num,
    ROUND(COUNT(*)/(SELECT COUNT(*) FROM olist_orders)*100,2) AS ratio
FROM olist_orders
GROUP BY order_status
ORDER BY count_num DESC;

-- 3. 月度订单&营收趋势
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price + oi.freight_value),2) AS revenue
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 4. 支付渠道分布
SELECT
    payment_type,
    COUNT(*) AS order_count,
    ROUND(SUM(payment_value),2) AS total_amount
FROM olist_order_payments
GROUP BY payment_type
ORDER BY order_count DESC;

-- 5 用户所在州Top10
SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS customer_count,
    ROUND(SUM(oi.price + oi.freight_value),2) AS total_revenue
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY customer_count DESC
LIMIT 10;

-- 6 用户消费金额分层
WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value) AS total_spending
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_spending < 100 THEN '低消费(<100)'
        WHEN total_spending < 500 THEN '中消费(100-500)'
        WHEN total_spending < 1000 THEN '高消费(500-1000)'
        ELSE '超高消费(>1000)'
    END AS spending_level,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*)/(SELECT COUNT(*) FROM customer_spending)*100,2) AS ratio
FROM customer_spending
GROUP BY spending_level
ORDER BY customer_count DESC;

-- 7 平台复购率
WITH customer_order_count AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_customers c
    JOIN olist_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(CASE WHEN order_count >= 2 THEN customer_unique_id END) AS repeat_users,
    COUNT(*) AS all_users,
    ROUND(COUNT(CASE WHEN order_count >= 2 THEN customer_unique_id END)/COUNT(*)*100,2) AS repurchase_rate
FROM customer_order_count;


-- 8 销量TOP10类目（英文名称）
SELECT
    p.product_category_name AS category_name,
    COUNT(oi.order_item_id) AS sales_volume,
    ROUND(SUM(oi.price),2) AS sales_revenue
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
GROUP BY category_name
ORDER BY sales_volume DESC
LIMIT 10;

-- 9 整体配送时效
SELECT
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),1) AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)),1) AS avg_early_days
FROM olist_orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_estimated_delivery_date IS NOT NULL;

-- 10 订单超时延迟占比
WITH order_delivery AS (
    SELECT
        order_id,
        DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS delivery_diff
    FROM olist_orders
    WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    COUNT(CASE WHEN delivery_diff > 0 THEN order_id END) AS overdue_orders,
    COUNT(*) AS total_deliver_orders,
    ROUND(COUNT(CASE WHEN delivery_diff > 0 THEN order_id END)/COUNT(*)*100,2) AS overdue_rate
FROM order_delivery;


-- 11 RFM 用户分层
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
        recency,
        frequency,
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
        WHEN r_score >= 4 AND f_score >= 4 AND m_score < 4 THEN '一般价值用户'
        WHEN r_score >= 4 AND f_score < 4 AND m_score < 4 THEN '一般发展用户'
        WHEN r_score < 4 AND f_score >= 4 AND m_score < 4 THEN '一般保持用户'
        ELSE '一般挽留用户'
    END AS user_type,
    COUNT(*) AS user_count,
    ROUND(SUM(monetary),2) AS total_revenue,
    ROUND(COUNT(*)/(SELECT COUNT(*) FROM rfm_score)*100,2) AS user_ratio,
    ROUND(SUM(monetary)/(SELECT SUM(monetary) FROM rfm_score)*100,2) AS revenue_ratio
FROM rfm_score
GROUP BY user_type
ORDER BY revenue_ratio DESC;