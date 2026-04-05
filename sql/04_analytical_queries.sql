-- аналитические запросы для проверки схемы нашей


-- общая статистика продаж
SELECT 
    COUNT(*) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    ROUND(AVG(total_price)::numeric, 2) AS avg_sale_amount
FROM fact_sales;

-- продажи по категориям товаров
SELECT 
    cat.category_name,
    COUNT(fs.sale_id) AS sales_count,
    SUM(fs.quantity) AS total_quantity,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_category cat ON p.category_id = cat.category_id
GROUP BY cat.category_name
ORDER BY total_revenue DESC;

-- топ-10 товаров по выручке
SELECT 
    p.product_name,
    cat.category_name,
    br.brand_name,
    COUNT(fs.sale_id) AS sales_count,
    SUM(fs.quantity) AS total_quantity,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_category cat ON p.category_id = cat.category_id
JOIN dim_brand br ON p.brand_id = br.brand_id
GROUP BY p.product_name, cat.category_name, br.brand_name
ORDER BY total_revenue DESC
LIMIT 10;

-- продажи по городам 
SELECT 
    c.city_name,
    c.state,
    co.country_name,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_store st ON fs.store_id = st.store_id
JOIN dim_city c ON st.city_id = c.city_id
JOIN dim_country co ON c.country_id = co.country_id
GROUP BY c.city_name, c.state, co.country_name
ORDER BY total_revenue DESC
LIMIT 10;

-- продажи по месяцам
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_date d ON fs.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- Запрос 6: Эффективность продавцов
SELECT 
    s.first_name || ' ' || s.last_name AS seller_name,
    co.country_name AS seller_country,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue,
    ROUND(AVG(fs.total_price)::numeric, 2) AS avg_sale_amount
FROM fact_sales fs
JOIN dim_seller s ON fs.seller_id = s.seller_id
LEFT JOIN dim_city ci ON s.city_id = ci.city_id
LEFT JOIN dim_country co ON ci.country_id = co.country_id
GROUP BY s.first_name, s.last_name, co.country_name
ORDER BY total_revenue DESC
LIMIT 10;

-- анализ покупателей по типу питомца
SELECT 
    c.pet_type,
    COUNT(DISTINCT c.customer_id) AS customers_count,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue,
    ROUND(AVG(fs.total_price)::numeric, 2) AS avg_sale_amount
FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
WHERE c.pet_type IS NOT NULL
GROUP BY c.pet_type
ORDER BY total_revenue DESC;

-- продажи по брендам и поставщикам
SELECT 
    br.brand_name,
    sup.supplier_name,
    ci.city_name AS supplier_city,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
JOIN dim_brand br ON p.brand_id = br.brand_id
JOIN dim_supplier sup ON p.supplier_id = sup.supplier_id
LEFT JOIN dim_city ci ON sup.city_id = ci.city_id
GROUP BY br.brand_name, sup.supplier_name, ci.city_name
ORDER BY total_revenue DESC
LIMIT 10;

-- анализ рейтингов товаров
SELECT 
    CASE 
        WHEN p.rating >= 4.5 THEN '4.5-5.0'
        WHEN p.rating >= 4.0 THEN '4.0-4.5'
        WHEN p.rating >= 3.5 THEN '3.5-4.0'
        WHEN p.rating >= 3.0 THEN '3.0-3.5'
        ELSE 'Below 3.0'
    END AS rating_range,
    COUNT(DISTINCT p.product_id) AS products_count,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_product p ON fs.product_id = p.product_id
WHERE p.rating IS NOT NULL
GROUP BY rating_range
ORDER BY rating_range DESC;

-- сравнение продаж в выходные и будни
SELECT 
    CASE WHEN d.is_weekend THEN 'Выходные' ELSE 'Будни' END AS day_type,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue,
    ROUND(AVG(fs.total_price)::numeric, 2) AS avg_sale_amount
FROM fact_sales fs
JOIN dim_date d ON fs.date_id = d.date_id
GROUP BY d.is_weekend
ORDER BY day_type;

-- топ магазинов по выручке
SELECT 
    st.store_name,
    ci.city_name,
    co.country_name,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_store st ON fs.store_id = st.store_id
JOIN dim_city ci ON st.city_id = ci.city_id
JOIN dim_country co ON ci.country_id = co.country_id
GROUP BY st.store_name, ci.city_name, co.country_name
ORDER BY total_revenue DESC
LIMIT 10;

-- анализ по странам (демонстрация нормализации)
SELECT 
    co.country_name,
    COUNT(DISTINCT c.customer_id) AS customers_count,
    COUNT(fs.sale_id) AS sales_count,
    ROUND(SUM(fs.total_price)::numeric, 2) AS total_revenue
FROM fact_sales fs
JOIN dim_customer c ON fs.customer_id = c.customer_id
LEFT JOIN dim_city ci ON c.city_id = ci.city_id
LEFT JOIN dim_country co ON ci.country_id = co.country_id
GROUP BY co.country_name
ORDER BY total_revenue DESC
LIMIT 10;
