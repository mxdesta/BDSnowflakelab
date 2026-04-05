-- создаем исходную таблицу для импорта csvшек


CREATE TABLE IF NOT EXISTS mock_data (
    id SERIAL PRIMARY KEY,
    source_id INTEGER,
    
    -- информация о покупателе
    customer_first_name VARCHAR(100),
    customer_last_name VARCHAR(100),
    customer_age INTEGER,
    customer_email VARCHAR(255),
    customer_country VARCHAR(100),
    customer_postal_code VARCHAR(50),
    customer_pet_type VARCHAR(50),
    customer_pet_name VARCHAR(100),
    customer_pet_breed VARCHAR(100),
    
    -- информация о продавце
    seller_first_name VARCHAR(100),
    seller_last_name VARCHAR(100),
    seller_email VARCHAR(255),
    seller_country VARCHAR(100),
    seller_postal_code VARCHAR(50),
    
    -- Информация о товаре
    product_name VARCHAR(255),
    product_category VARCHAR(100),
    product_price DECIMAL(10, 2),
    product_quantity INTEGER,
    
    -- информация о продаже
    sale_date DATE,
    sale_customer_id INTEGER,
    sale_seller_id INTEGER,
    sale_product_id INTEGER,
    sale_quantity INTEGER,
    sale_total_price DECIMAL(10, 2),
    
    -- информация о магазине
    store_name VARCHAR(255),
    store_location VARCHAR(255),
    store_city VARCHAR(100),
    store_state VARCHAR(100),
    store_country VARCHAR(100),
    store_phone VARCHAR(50),
    store_email VARCHAR(255),
    
    -- доп. информация о товаре
    pet_category VARCHAR(100),
    product_weight DECIMAL(10, 2),
    product_color VARCHAR(50),
    product_size VARCHAR(50),
    product_brand VARCHAR(100),
    product_material VARCHAR(100),
    product_description TEXT,
    product_rating DECIMAL(3, 2),
    product_reviews INTEGER,
    product_release_date DATE,
    product_expiry_date DATE,
    
    -- информация о поставщике
    supplier_name VARCHAR(255),
    supplier_contact VARCHAR(255),
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    supplier_address TEXT,
    supplier_city VARCHAR(100),
    supplier_country VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE mock_data IS 'Исходная таблица с данными из CSV файлов';

CREATE INDEX IF NOT EXISTS idx_mock_data_sale_date ON mock_data(sale_date);
CREATE INDEX IF NOT EXISTS idx_mock_data_customer ON mock_data(customer_first_name, customer_last_name);
CREATE INDEX IF NOT EXISTS idx_mock_data_product ON mock_data(product_name);

SELECT 'Таблица mock_data успешно создана!' AS status;
