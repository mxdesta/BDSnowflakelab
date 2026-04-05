-- DML скрипты здесь

-- создаем индексы на исходной таб., чтоб джоины ускорить
CREATE INDEX IF NOT EXISTS idx_mock_customer_email ON mock_data(customer_email);
CREATE INDEX IF NOT EXISTS idx_mock_seller_email ON mock_data(seller_email);
CREATE INDEX IF NOT EXISTS idx_mock_product_name ON mock_data(product_name);
CREATE INDEX IF NOT EXISTS idx_mock_store_name ON mock_data(store_name);
CREATE INDEX IF NOT EXISTS idx_mock_supplier_name ON mock_data(supplier_name);
CREATE INDEX IF NOT EXISTS idx_mock_sale_date ON mock_data(sale_date);

-- заполняем справочник стран
INSERT INTO dim_country (country_name)
SELECT DISTINCT country FROM (
    SELECT customer_country AS country FROM mock_data WHERE customer_country IS NOT NULL AND customer_country != ''
    UNION
    SELECT seller_country FROM mock_data WHERE seller_country IS NOT NULL AND seller_country != ''
    UNION
    SELECT store_country FROM mock_data WHERE store_country IS NOT NULL AND store_country != ''
    UNION
    SELECT supplier_country FROM mock_data WHERE supplier_country IS NOT NULL AND supplier_country != ''
) AS countries
ON CONFLICT (country_name) DO NOTHING;

-- заполняем правочник городов
INSERT INTO dim_city (city_name, state, country_id)
SELECT DISTINCT city_name, state, c.country_id
FROM (
    SELECT store_city AS city_name, store_state AS state, store_country AS country
    FROM mock_data WHERE store_city IS NOT NULL AND store_city != ''
    UNION
    SELECT supplier_city, NULL, supplier_country
    FROM mock_data WHERE supplier_city IS NOT NULL AND supplier_city != ''
) AS cities
LEFT JOIN dim_country c ON c.country_name = cities.country
ON CONFLICT (city_name, state, country_id) DO NOTHING;

-- заполняем справочник категорий
INSERT INTO dim_category (category_name)
SELECT DISTINCT product_category
FROM mock_data
WHERE product_category IS NOT NULL AND product_category != ''
ON CONFLICT (category_name) DO NOTHING;

-- заполняем справочник брендов
INSERT INTO dim_brand (brand_name)
SELECT DISTINCT product_brand
FROM mock_data
WHERE product_brand IS NOT NULL AND product_brand != ''
ON CONFLICT (brand_name) DO NOTHING;

-- заполгяем справочник поставщиков
INSERT INTO dim_supplier (supplier_name, supplier_contact, supplier_email, supplier_phone, supplier_address, city_id)
SELECT DISTINCT ON (md.supplier_name)
    md.supplier_name,
    md.supplier_contact,
    md.supplier_email,
    md.supplier_phone,
    md.supplier_address,
    c.city_id
FROM mock_data md
LEFT JOIN dim_country co ON co.country_name = md.supplier_country
LEFT JOIN dim_city c ON c.city_name = md.supplier_city AND c.country_id = co.country_id
WHERE md.supplier_name IS NOT NULL AND md.supplier_name != ''
ORDER BY md.supplier_name, md.id;

-- заполняем справочник покупателей
INSERT INTO dim_customer (first_name, last_name, age, email, postal_code, city_id, pet_type, pet_name, pet_breed)
SELECT DISTINCT ON (md.customer_email)
    md.customer_first_name,
    md.customer_last_name,
    md.customer_age,
    md.customer_email,
    md.customer_postal_code,
    c.city_id,
    md.customer_pet_type,
    md.customer_pet_name,
    md.customer_pet_breed
FROM mock_data md
LEFT JOIN dim_country co ON co.country_name = md.customer_country
LEFT JOIN dim_city c ON c.country_id = co.country_id
WHERE md.customer_first_name IS NOT NULL
ORDER BY md.customer_email, md.id;

-- заполняем справочник продавцов
INSERT INTO dim_seller (first_name, last_name, email, postal_code, city_id)
SELECT DISTINCT ON (md.seller_email)
    md.seller_first_name,
    md.seller_last_name,
    md.seller_email,
    md.seller_postal_code,
    c.city_id
FROM mock_data md
LEFT JOIN dim_country co ON co.country_name = md.seller_country
LEFT JOIN dim_city c ON c.country_id = co.country_id
WHERE md.seller_first_name IS NOT NULL
ORDER BY md.seller_email, md.id;

-- заполняем справочник магазинов
INSERT INTO dim_store (store_name, location, city_id, phone, email)
SELECT DISTINCT ON (md.store_name)
    md.store_name,
    md.store_location,
    c.city_id,
    md.store_phone,
    md.store_email
FROM mock_data md
LEFT JOIN dim_country co ON co.country_name = md.store_country
LEFT JOIN dim_city c ON c.city_name = md.store_city AND c.state = md.store_state AND c.country_id = co.country_id
WHERE md.store_name IS NOT NULL
ORDER BY md.store_name, md.id;

-- заполняем справочник товаров
INSERT INTO dim_product (product_name, category_id, brand_id, supplier_id, price, weight, color, size, material, description, rating, reviews, release_date, expiry_date)
SELECT DISTINCT ON (md.product_name)
    md.product_name,
    cat.category_id,
    br.brand_id,
    sup.supplier_id,
    md.product_price,
    md.product_weight,
    md.product_color,
    md.product_size,
    md.product_material,
    md.product_description,
    md.product_rating,
    md.product_reviews,
    md.product_release_date,
    md.product_expiry_date
FROM mock_data md
LEFT JOIN dim_category cat ON cat.category_name = md.product_category
LEFT JOIN dim_brand br ON br.brand_name = md.product_brand
LEFT JOIN dim_supplier sup ON sup.supplier_name = md.supplier_name
WHERE md.product_name IS NOT NULL
ORDER BY md.product_name, md.id;

-- справочник дат
INSERT INTO dim_date (date_value, year, quarter, month, month_name, day, day_of_week, day_name, week_of_year, is_weekend)
SELECT DISTINCT
    sale_date,
    EXTRACT(YEAR FROM sale_date),
    EXTRACT(QUARTER FROM sale_date),
    EXTRACT(MONTH FROM sale_date),
    TO_CHAR(sale_date, 'Month'),
    EXTRACT(DAY FROM sale_date),
    EXTRACT(DOW FROM sale_date),
    TO_CHAR(sale_date, 'Day'),
    EXTRACT(WEEK FROM sale_date),
    CASE WHEN EXTRACT(DOW FROM sale_date) IN (0, 6) THEN TRUE ELSE FALSE END
FROM mock_data
WHERE sale_date IS NOT NULL
ON CONFLICT (date_value) DO NOTHING;

-- Создаем дополнительные индексы для оптимизации JOIN в fact_sales
CREATE INDEX IF NOT EXISTS idx_dim_customer_email ON dim_customer(email);
CREATE INDEX IF NOT EXISTS idx_dim_seller_email ON dim_seller(email);
CREATE INDEX IF NOT EXISTS idx_dim_product_name ON dim_product(product_name);
CREATE INDEX IF NOT EXISTS idx_dim_store_name ON dim_store(store_name);
CREATE INDEX IF NOT EXISTS idx_dim_date_value ON dim_date(date_value);

-- фактовая таблицы продаж
INSERT INTO fact_sales (date_id, customer_id, seller_id, product_id, store_id, quantity, total_price)
SELECT 
    d.date_id,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    md.sale_quantity,
    md.sale_total_price
FROM mock_data md
INNER JOIN dim_date d ON d.date_value = md.sale_date
INNER JOIN dim_customer c ON c.email = md.customer_email
INNER JOIN dim_seller s ON s.email = md.seller_email
INNER JOIN dim_product p ON p.product_name = md.product_name
INNER JOIN dim_store st ON st.store_name = md.store_name;

-- Итоговая статистика
SELECT 
    'dim_country' AS table_name, COUNT(*) AS row_count FROM dim_country
UNION ALL
SELECT 'dim_city', COUNT(*) FROM dim_city
UNION ALL
SELECT 'dim_category', COUNT(*) FROM dim_category
UNION ALL
SELECT 'dim_brand', COUNT(*) FROM dim_brand
UNION ALL
SELECT 'dim_supplier', COUNT(*) FROM dim_supplier
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_seller', COUNT(*) FROM dim_seller
UNION ALL
SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales
ORDER BY table_name;
