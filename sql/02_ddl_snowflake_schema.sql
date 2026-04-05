-- таб. измерений стран
CREATE TABLE IF NOT EXISTS dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_country IS 'Справочник стран (измерение третьего уровня)';

-- таб. измерений городов
CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country_id INTEGER REFERENCES dim_country(country_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city_name, state, country_id)
);

COMMENT ON TABLE dim_city IS 'Справочник городов (измерение второго уровня)';

-- таб. измерений для категорий товаров
CREATE TABLE IF NOT EXISTS dim_category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_category IS 'Справочник категорий товаров';

-- таб. измерений для брендов
CREATE TABLE IF NOT EXISTS dim_brand (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_brand IS 'Справочник брендов';

-- таб. измерений для поставщиков
CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_contact VARCHAR(255),
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    supplier_address TEXT,
    city_id INTEGER REFERENCES dim_city(city_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_supplier IS 'Справочник поставщиков';

-- таб. измерений для покупателей
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INTEGER,
    email VARCHAR(255),
    postal_code VARCHAR(50),
    city_id INTEGER REFERENCES dim_city(city_id),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_customer IS 'Справочник покупателей';

-- таб. измерений для продавцов
CREATE TABLE IF NOT EXISTS dim_seller (
    seller_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    postal_code VARCHAR(50),
    city_id INTEGER REFERENCES dim_city(city_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_seller IS 'Справочник продавцов';

-- таб. измерений магазинов 
CREATE TABLE IF NOT EXISTS dim_store (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    city_id INTEGER REFERENCES dim_city(city_id),
    phone VARCHAR(50),
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_store IS 'Справочник магазинов';

-- таб. измерений товаров 
CREATE TABLE IF NOT EXISTS dim_product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id INTEGER REFERENCES dim_category(category_id),
    brand_id INTEGER REFERENCES dim_brand(brand_id),
    supplier_id INTEGER REFERENCES dim_supplier(supplier_id),
    price DECIMAL(10, 2),
    weight DECIMAL(10, 2),
    color VARCHAR(50),
    size VARCHAR(50),
    material VARCHAR(100),
    description TEXT,
    rating DECIMAL(3, 2),
    reviews INTEGER,
    release_date DATE,
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_product IS 'Справочник товаров';

-- таблица измерений дат
CREATE TABLE IF NOT EXISTS dim_date (
    date_id SERIAL PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    week_of_year INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dim_date IS 'Справочник дат';

-- фактовая таб. продаж
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id SERIAL PRIMARY KEY,
    date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    customer_id INTEGER NOT NULL REFERENCES dim_customer(customer_id),
    seller_id INTEGER NOT NULL REFERENCES dim_seller(seller_id),
    product_id INTEGER NOT NULL REFERENCES dim_product(product_id),
    store_id INTEGER NOT NULL REFERENCES dim_store(store_id),
    
    quantity INTEGER NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE fact_sales IS 'Фактовая таблица продаж';

-- тут создаем индексы, чтоб оптимизировать поиск в нашей БД 
CREATE INDEX idx_fact_sales_date ON fact_sales(date_id);
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_sales_seller ON fact_sales(seller_id);
CREATE INDEX idx_fact_sales_product ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_store ON fact_sales(store_id);

CREATE INDEX idx_dim_customer_city ON dim_customer(city_id);
CREATE INDEX idx_dim_seller_city ON dim_seller(city_id);
CREATE INDEX idx_dim_city_country ON dim_city(country_id);
CREATE INDEX idx_dim_store_city ON dim_store(city_id);
CREATE INDEX idx_dim_product_category ON dim_product(category_id);
CREATE INDEX idx_dim_product_brand ON dim_product(brand_id);
CREATE INDEX idx_dim_product_supplier ON dim_product(supplier_id);
CREATE INDEX idx_dim_supplier_city ON dim_supplier(city_id);

SELECT 'Схема Снежинка успешно создана!' AS status;
