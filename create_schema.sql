-- SQL Script for Creating the 'solving_inventory' Schema and Tables
-- Designed for Urban Retail Co. Inventory Analysis Project

-- Create the schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS solving_inventory;

-- Set the search path to the new schema
SET search_path TO solving_inventory;

-- -----------------------------------------------------
-- Table: Products
-- Purpose: Stores unique information about each product.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Products (
    product_id VARCHAR(50) PRIMARY KEY,
    category VARCHAR(100) -- Category the product belongs to (e.g., 'Groceries', 'Electronics')
);

COMMENT ON TABLE solving_inventory.Products IS 'Stores details about each unique product.';
COMMENT ON COLUMN solving_inventory.Products.product_id IS 'Unique identifier for the product (e.g., P0001).';
COMMENT ON COLUMN solving_inventory.Products.category IS 'Category the product belongs to (e.g., Groceries, Electronics).';

-- -----------------------------------------------------
-- Table: Stores
-- Purpose: Stores unique information about each retail store.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.Stores (
    store_id VARCHAR(50) PRIMARY KEY,
    region VARCHAR(100) -- Geographic region where the store is located (e.g., 'North', 'South')
);

COMMENT ON TABLE solving_inventory.Stores IS 'Stores details about each unique retail store.';
COMMENT ON COLUMN solving_inventory.Stores.store_id IS 'Unique identifier for the store (e.g., S001).';
COMMENT ON COLUMN solving_inventory.Stores.region IS 'Geographic region where the store is located (e.g., North, South).';

-- -----------------------------------------------------
-- Table: InventorySnapshots
-- Purpose: Records daily inventory levels, sales, orders, forecasts, and related contextual information.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS solving_inventory.InventorySnapshots (
    date DATE NOT NULL,
    store_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    inventory_level INTEGER, -- Stock level at the time of the snapshot
    units_sold INTEGER, -- Number of units sold on that date
    units_ordered INTEGER, -- Number of units ordered on that date
    demand_forecast DECIMAL(10, 2), -- Forecasted demand for the product
    price DECIMAL(10, 2), -- Selling price of the product on that date
    discount_percentage INTEGER, -- Discount percentage applied (0-100)
    weather_condition VARCHAR(50), -- Weather condition on that date (e.g., 'Rainy', 'Sunny')
    is_holiday_promotion BOOLEAN, -- Flag indicating if a holiday or promotion was active (True/False)
    competitor_price DECIMAL(10, 2), -- Competitor's price for a similar product on that date
    seasonality VARCHAR(50), -- Season associated with the date (e.g., 'Autumn', 'Summer')
    PRIMARY KEY (date, store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES solving_inventory.Stores (store_id),
    FOREIGN KEY (product_id) REFERENCES solving_inventory.Products (product_id)
);

COMMENT ON TABLE solving_inventory.InventorySnapshots IS 'Records daily inventory levels, sales, orders, forecasts, and related contextual information.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.date IS 'The date of the snapshot.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.store_id IS 'Foreign key referencing Stores.store_id.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.product_id IS 'Foreign key referencing Products.product_id.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.inventory_level IS 'Stock level at the time of the snapshot.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.units_sold IS 'Number of units sold on that date.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.units_ordered IS 'Number of units ordered on that date.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.demand_forecast IS 'Forecasted demand for the product.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.price IS 'Selling price of the product on that date.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.discount_percentage IS 'Discount percentage applied (0-100).';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.weather_condition IS 'Weather condition on that date (e.g., Rainy, Sunny).';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.is_holiday_promotion IS 'Flag indicating if a holiday or promotion was active (True/False).';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.competitor_price IS 'Competitor price for a similar product on that date.';
COMMENT ON COLUMN solving_inventory.InventorySnapshots.seasonality IS 'Season associated with the date (e.g., Autumn, Summer).';

-- -----------------------------------------------------
-- Indexing for Performance Optimization
-- Create indexes on foreign keys and frequently queried columns
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_inventorysnapshots_store_id ON solving_inventory.InventorySnapshots (store_id);
CREATE INDEX IF NOT EXISTS idx_inventorysnapshots_product_id ON solving_inventory.InventorySnapshots (product_id);
CREATE INDEX IF NOT EXISTS idx_inventorysnapshots_date ON solving_inventory.InventorySnapshots (date);
CREATE INDEX IF NOT EXISTS idx_products_category ON solving_inventory.Products (category);
CREATE INDEX IF NOT EXISTS idx_stores_region ON solving_inventory.Stores (region);

-- End of Script

