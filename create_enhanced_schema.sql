-- SQL Script for Creating the 'solving_inventory' Schema and Tables with Optimized Indexing
-- Designed for Urban Retail Co. Inventory Analysis Project

-- Create the schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS solving_inventory;

-- Set the search path to the new schema
SET search_path TO solving_inventory;

-- -----------------------------------------------------
-- Table: Categories
-- Purpose: Organizes products into hierarchical categories
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id) REFERENCES solving_inventory.Categories (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX idx_category_parent ON solving_inventory.Categories (parent_category_id);

COMMENT ON TABLE solving_inventory.Categories IS 'Organizes products into hierarchical categories.';

-- -----------------------------------------------------
-- Table: Products
-- Purpose: Stores comprehensive details about each unique product
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    description TEXT,
    unit_cost DECIMAL(10,2) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    min_stock_level INT NOT NULL,
    max_stock_level INT NOT NULL,
    lead_time_days INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES solving_inventory.Categories (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Indexes for Products table
CREATE INDEX idx_product_category ON solving_inventory.Products (category_id);
CREATE INDEX idx_product_active_category ON solving_inventory.Products (is_active, category_id);
CREATE INDEX idx_product_price ON solving_inventory.Products (unit_price);
CREATE INDEX idx_product_stock_levels ON solving_inventory.Products (min_stock_level, max_stock_level);

COMMENT ON TABLE solving_inventory.Products IS 'Stores comprehensive details about each unique product.';

-- -----------------------------------------------------
-- Table: Suppliers
-- Purpose: Stores information about product suppliers
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(100),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    address TEXT,
    performance_rating DECIMAL(3,2),
    active_since DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Indexes for Suppliers table
CREATE INDEX idx_supplier_name ON solving_inventory.Suppliers (supplier_name);
CREATE INDEX idx_supplier_active ON solving_inventory.Suppliers (is_active);
CREATE INDEX idx_supplier_performance ON solving_inventory.Suppliers (performance_rating);

COMMENT ON TABLE solving_inventory.Suppliers IS 'Stores information about product suppliers.';

-- -----------------------------------------------------
-- Table: Stores
-- Purpose: Stores details about each retail store location
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Stores (
    store_id VARCHAR(50) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    manager_name VARCHAR(100),
    contact_phone VARCHAR(20),
    store_size_sqft INT,
    opening_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Indexes for Stores table
CREATE INDEX idx_store_region ON solving_inventory.Stores (region);
CREATE INDEX idx_store_active ON solving_inventory.Stores (is_active);
CREATE INDEX idx_store_name ON solving_inventory.Stores (store_name);

COMMENT ON TABLE solving_inventory.Stores IS 'Stores details about each retail store location.';

-- -----------------------------------------------------
-- Table: Inventory
-- Purpose: Tracks current inventory levels across all stores
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Inventory (
    inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    store_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity_on_hand INT NOT NULL,
    quantity_reserved INT DEFAULT 0,
    quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
    last_counted_date DATE,
    shelf_location VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES solving_inventory.Stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES solving_inventory.Products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_inventory_store_product UNIQUE (store_id, product_id)
);

-- Indexes for Inventory table
CREATE INDEX idx_inventory_store_product ON solving_inventory.Inventory (store_id, product_id);
CREATE INDEX idx_inventory_quantity ON solving_inventory.Inventory (quantity_on_hand);
CREATE INDEX idx_inventory_available ON solving_inventory.Inventory (quantity_available);
CREATE INDEX idx_inventory_last_counted ON solving_inventory.Inventory (last_counted_date);

COMMENT ON TABLE solving_inventory.Inventory IS 'Tracks current inventory levels across all stores.';

-- -----------------------------------------------------
-- Table: Transactions
-- Purpose: Records all inventory movements (sales, receipts, adjustments, transfers)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_type ENUM('SALE', 'RECEIPT', 'ADJUSTMENT', 'TRANSFER_OUT', 'TRANSFER_IN') NOT NULL,
    store_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    transaction_date DATETIME NOT NULL,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    reference_id VARCHAR(100),
    notes TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transaction_store FOREIGN KEY (store_id) REFERENCES solving_inventory.Stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transaction_product FOREIGN KEY (product_id) REFERENCES solving_inventory.Products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Indexes for Transactions table
CREATE INDEX idx_transaction_store_product_date ON solving_inventory.Transactions (store_id, product_id, transaction_date);
CREATE INDEX idx_transaction_date ON solving_inventory.Transactions (transaction_date);
CREATE INDEX idx_transaction_type ON solving_inventory.Transactions (transaction_type);
CREATE INDEX idx_transaction_reference ON solving_inventory.Transactions (reference_id);

COMMENT ON TABLE solving_inventory.Transactions IS 'Records all inventory movements (sales, receipts, adjustments, transfers).';

-- -----------------------------------------------------
-- Table: Purchase_Orders
-- Purpose: Manages orders placed to suppliers for restocking
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Purchase_Orders (
    po_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    store_id VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    status ENUM('DRAFT', 'SUBMITTED', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED') NOT NULL,
    total_amount DECIMAL(12,2),
    payment_terms VARCHAR(100),
    notes TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES solving_inventory.Suppliers (supplier_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_po_store FOREIGN KEY (store_id) REFERENCES solving_inventory.Stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Indexes for Purchase_Orders table
CREATE INDEX idx_po_supplier ON solving_inventory.Purchase_Orders (supplier_id);
CREATE INDEX idx_po_store ON solving_inventory.Purchase_Orders (store_id);
CREATE INDEX idx_po_status_date ON solving_inventory.Purchase_Orders (status, expected_delivery_date);
CREATE INDEX idx_po_order_date ON solving_inventory.Purchase_Orders (order_date);

COMMENT ON TABLE solving_inventory.Purchase_Orders IS 'Manages orders placed to suppliers for restocking.';

-- -----------------------------------------------------
-- Table: Purchase_Order_Items
-- Purpose: Details individual line items within purchase orders
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Purchase_Order_Items (
    po_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    po_id BIGINT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    quantity_ordered INT NOT NULL,
    quantity_received INT DEFAULT 0,
    unit_cost DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity_ordered * unit_cost) STORED,
    expected_delivery_date DATE,
    status ENUM('PENDING', 'PARTIAL', 'COMPLETE', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_poitem_po FOREIGN KEY (po_id) REFERENCES solving_inventory.Purchase_Orders (po_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_poitem_product FOREIGN KEY (product_id) REFERENCES solving_inventory.Products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Indexes for Purchase_Order_Items table
CREATE INDEX idx_poitem_po ON solving_inventory.Purchase_Order_Items (po_id);
CREATE INDEX idx_poitem_product ON solving_inventory.Purchase_Order_Items (product_id);
CREATE INDEX idx_poitem_po_product ON solving_inventory.Purchase_Order_Items (po_id, product_id);
CREATE INDEX idx_poitem_status ON solving_inventory.Purchase_Order_Items (status);

COMMENT ON TABLE solving_inventory.Purchase_Order_Items IS 'Details individual line items within purchase orders.';

-- -----------------------------------------------------
-- Query Optimization: Partitioning for Transactions Table
-- Partitioning large tables by date range improves query performance
-- -----------------------------------------------------
ALTER TABLE solving_inventory.Transactions
PARTITION BY RANGE (YEAR(transaction_date)) (
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);

-- End of Schema Creation Script
