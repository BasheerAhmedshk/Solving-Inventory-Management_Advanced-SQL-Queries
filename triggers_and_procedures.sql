-- SQL Script for Automated Reorder Triggers and Stored Procedures
-- Designed for Urban Retail Co. Inventory Management System

-- Set the search path to the schema
SET search_path TO solving_inventory;

-- -----------------------------------------------------
-- Trigger: Check Inventory Levels After Update
-- Purpose: Automatically monitors inventory thresholds and creates purchase orders when needed
-- -----------------------------------------------------

-- First, create a function that will be called by the trigger
CREATE OR REPLACE FUNCTION solving_inventory.check_inventory_levels()
RETURNS TRIGGER AS $$
DECLARE
    v_min_stock_level INT;
    v_lead_time_days INT;
    v_avg_daily_sales DECIMAL(10,2);
    v_reorder_quantity INT;
    v_supplier_id INT;
    v_po_id BIGINT;
BEGIN
    -- Only proceed if inventory is below threshold
    SELECT p.min_stock_level, p.lead_time_days 
    INTO v_min_stock_level, v_lead_time_days
    FROM solving_inventory.Products p
    WHERE p.product_id = NEW.product_id;
    
    -- Check if inventory is below minimum stock level
    IF NEW.quantity_on_hand <= v_min_stock_level THEN
        -- Calculate average daily sales over the last 30 days
        SELECT COALESCE(AVG(quantity), 1) 
        INTO v_avg_daily_sales
        FROM solving_inventory.Transactions
        WHERE product_id = NEW.product_id
        AND store_id = NEW.store_id
        AND transaction_type = 'SALE'
        AND transaction_date >= (CURRENT_DATE - INTERVAL '30 days');
        
        -- Calculate reorder quantity (lead time * avg daily sales * 1.5 safety factor)
        v_reorder_quantity = CEIL((v_lead_time_days * v_avg_daily_sales) * 1.5);
        
        -- Find the best supplier (highest performance rating)
        SELECT supplier_id INTO v_supplier_id
        FROM solving_inventory.Suppliers
        WHERE is_active = TRUE
        ORDER BY performance_rating DESC
        LIMIT 1;
        
        -- If we have a supplier, create a purchase order
        IF v_supplier_id IS NOT NULL THEN
            -- Insert new purchase order
            INSERT INTO solving_inventory.Purchase_Orders (
                supplier_id, 
                store_id, 
                order_date, 
                expected_delivery_date, 
                status, 
                created_by
            ) VALUES (
                v_supplier_id,
                NEW.store_id,
                CURRENT_DATE,
                CURRENT_DATE + v_lead_time_days,
                'DRAFT',
                'AutoReorderSystem'
            )
            RETURNING po_id INTO v_po_id;
            
            -- Insert purchase order item
            INSERT INTO solving_inventory.Purchase_Order_Items (
                po_id,
                product_id,
                quantity_ordered,
                unit_cost,
                expected_delivery_date,
                status
            ) VALUES (
                v_po_id,
                NEW.product_id,
                v_reorder_quantity,
                (SELECT unit_cost FROM solving_inventory.Products WHERE product_id = NEW.product_id),
                CURRENT_DATE + v_lead_time_days,
                'PENDING'
            );
            
            -- Update the purchase order total
            UPDATE solving_inventory.Purchase_Orders
            SET total_amount = (
                SELECT SUM(line_total) 
                FROM solving_inventory.Purchase_Order_Items 
                WHERE po_id = v_po_id
            )
            WHERE po_id = v_po_id;
            
            -- Log the auto-reorder event
            INSERT INTO solving_inventory.Transactions (
                transaction_type,
                store_id,
                product_id,
                quantity,
                transaction_date,
                reference_id,
                notes,
                created_by
            ) VALUES (
                'ADJUSTMENT',
                NEW.store_id,
                NEW.product_id,
                0, -- Zero quantity as this is just a log entry
                NOW(),
                CONCAT('PO-', v_po_id),
                CONCAT('Auto-reorder triggered. Current stock: ', NEW.quantity_on_hand, ', Min level: ', v_min_stock_level),
                'AutoReorderSystem'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger that calls our function
CREATE TRIGGER trg_inventory_check_levels
AFTER UPDATE OF quantity_on_hand ON solving_inventory.Inventory
FOR EACH ROW
EXECUTE FUNCTION solving_inventory.check_inventory_levels();

-- -----------------------------------------------------
-- Stored Procedure: Process Purchase Order Receipt
-- Purpose: Updates inventory and purchase order status when items are received
-- -----------------------------------------------------
CREATE OR REPLACE PROCEDURE solving_inventory.process_purchase_order_receipt(
    p_po_id BIGINT,
    p_receipt_date DATE,
    p_received_by VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_po_item RECORD;
    v_store_id VARCHAR(50);
BEGIN
    -- Get the store ID from the purchase order
    SELECT store_id INTO v_store_id
    FROM solving_inventory.Purchase_Orders
    WHERE po_id = p_po_id;
    
    -- Process each item in the purchase order
    FOR v_po_item IN 
        SELECT * FROM solving_inventory.Purchase_Order_Items
        WHERE po_id = p_po_id AND status IN ('PENDING', 'PARTIAL')
    LOOP
        -- Update inventory
        UPDATE solving_inventory.Inventory
        SET quantity_on_hand = quantity_on_hand + v_po_item.quantity_ordered,
            last_counted_date = p_receipt_date,
            updated_at = NOW()
        WHERE store_id = v_store_id AND product_id = v_po_item.product_id;
        
        -- If no inventory record exists, create one
        IF NOT FOUND THEN
            INSERT INTO solving_inventory.Inventory (
                store_id,
                product_id,
                quantity_on_hand,
                quantity_reserved,
                last_counted_date
            ) VALUES (
                v_store_id,
                v_po_item.product_id,
                v_po_item.quantity_ordered,
                0,
                p_receipt_date
            );
        END IF;
        
        -- Record the receipt transaction
        INSERT INTO solving_inventory.Transactions (
            transaction_type,
            store_id,
            product_id,
            quantity,
            transaction_date,
            unit_price,
            total_amount,
            reference_id,
            notes,
            created_by
        ) VALUES (
            'RECEIPT',
            v_store_id,
            v_po_item.product_id,
            v_po_item.quantity_ordered,
            p_receipt_date,
            v_po_item.unit_cost,
            v_po_item.line_total,
            CONCAT('PO-', p_po_id),
            'Purchase order receipt',
            p_received_by
        );
        
        -- Update the purchase order item status
        UPDATE solving_inventory.Purchase_Order_Items
        SET status = 'COMPLETE',
            quantity_received = quantity_ordered,
            updated_at = NOW()
        WHERE po_item_id = v_po_item.po_item_id;
    END LOOP;
    
    -- Update the purchase order status
    UPDATE solving_inventory.Purchase_Orders
    SET status = 'DELIVERED',
        actual_delivery_date = p_receipt_date,
        updated_at = NOW()
    WHERE po_id = p_po_id;
    
    -- Commit the transaction
    COMMIT;
END;
$$;

-- -----------------------------------------------------
-- Stored Procedure: Calculate Reorder Points
-- Purpose: Dynamically calculates optimal reorder points based on sales history
-- -----------------------------------------------------
CREATE OR REPLACE PROCEDURE solving_inventory.calculate_reorder_points(
    p_safety_factor DECIMAL DEFAULT 1.5
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product RECORD;
    v_avg_daily_sales DECIMAL(10,2);
    v_sales_stddev DECIMAL(10,2);
    v_lead_time_days INT;
    v_reorder_point INT;
BEGIN
    -- Process each active product
    FOR v_product IN 
        SELECT * FROM solving_inventory.Products
        WHERE is_active = TRUE
    LOOP
        -- Calculate average daily sales
        SELECT COALESCE(AVG(daily_sales), 0), COALESCE(STDDEV(daily_sales), 1)
        INTO v_avg_daily_sales, v_sales_stddev
        FROM (
            SELECT 
                DATE(transaction_date) as sale_date,
                SUM(quantity) as daily_sales
            FROM solving_inventory.Transactions
            WHERE product_id = v_product.product_id
            AND transaction_type = 'SALE'
            AND transaction_date >= (CURRENT_DATE - INTERVAL '90 days')
            GROUP BY DATE(transaction_date)
        ) AS daily_sales;
        
        -- Get lead time
        v_lead_time_days = v_product.lead_time_days;
        
        -- Calculate reorder point using formula:
        -- Reorder Point = (Average Daily Sales * Lead Time) + Safety Stock
        -- Safety Stock = Safety Factor * Standard Deviation * SQRT(Lead Time)
        v_reorder_point = CEIL(
            (v_avg_daily_sales * v_lead_time_days) + 
            (p_safety_factor * v_sales_stddev * SQRT(v_lead_time_days))
        );
        
        -- Update the product with the new reorder point
        UPDATE solving_inventory.Products
        SET min_stock_level = GREATEST(v_reorder_point, 1), -- Ensure at least 1
            updated_at = NOW()
        WHERE product_id = v_product.product_id;
    END LOOP;
    
    -- Commit the transaction
    COMMIT;
END;
$$;

-- -----------------------------------------------------
-- Stored Procedure: Identify Slow Moving Inventory
-- Purpose: Identifies products with low turnover rates for potential action
-- -----------------------------------------------------
CREATE OR REPLACE PROCEDURE solving_inventory.identify_slow_moving_inventory(
    p_days_threshold INT DEFAULT 90,
    p_sales_threshold INT DEFAULT 5
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date DATE := CURRENT_DATE;
    v_cutoff_date DATE := v_current_date - p_days_threshold;
BEGIN
    -- Create temporary table to store results
    DROP TABLE IF EXISTS solving_inventory.temp_slow_moving;
    
    CREATE TEMPORARY TABLE solving_inventory.temp_slow_moving AS
    SELECT 
        i.store_id,
        s.store_name,
        s.region,
        i.product_id,
        p.product_name,
        p.category_id,
        c.category_name,
        i.quantity_on_hand,
        p.unit_cost,
        (i.quantity_on_hand * p.unit_cost) AS inventory_value,
        COALESCE(SUM(t.quantity), 0) AS total_sales_quantity,
        COALESCE(MAX(t.transaction_date), NULL) AS last_sale_date,
        CASE 
            WHEN MAX(t.transaction_date) IS NULL THEN v_current_date - i.created_at::date
            ELSE v_current_date - MAX(t.transaction_date)::date
        END AS days_since_last_sale
    FROM 
        solving_inventory.Inventory i
    JOIN 
        solving_inventory.Products p ON i.product_id = p.product_id
    JOIN 
        solving_inventory.Categories c ON p.category_id = c.category_id
    JOIN 
        solving_inventory.Stores s ON i.store_id = s.store_id
    LEFT JOIN 
        solving_inventory.Transactions t ON 
            i.product_id = t.product_id AND 
            i.store_id = t.store_id AND 
            t.transaction_type = 'SALE' AND
            t.transaction_date >= v_cutoff_date
    WHERE 
        i.quantity_on_hand > 0
    GROUP BY 
        i.store_id, s.store_name, s.region, i.product_id, p.product_name, 
        p.category_id, c.category_name, i.quantity_on_hand, p.unit_cost, i.created_at
    HAVING 
        COALESCE(SUM(t.quantity), 0) < p_sales_threshold
    ORDER BY 
        inventory_value DESC;
        
    -- Output can be queried from the temporary table
    -- The table will be automatically dropped at the end of the session
END;
$$;

-- -----------------------------------------------------
-- Trigger: Update Product Price History
-- Purpose: Maintains a history of price changes for analysis
-- -----------------------------------------------------

-- First, create a price history table
CREATE TABLE IF NOT EXISTS solving_inventory.Product_Price_History (
    history_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    old_cost DECIMAL(10,2),
    new_cost DECIMAL(10,2),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50),
    CONSTRAINT fk_price_history_product FOREIGN KEY (product_id) REFERENCES solving_inventory.Products (product_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_price_history_product ON solving_inventory.Product_Price_History (product_id);
CREATE INDEX idx_price_history_date ON solving_inventory.Product_Price_History (change_date);

-- Create the trigger function
CREATE OR REPLACE FUNCTION solving_inventory.track_price_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only track if price or cost has changed
    IF (OLD.unit_price <> NEW.unit_price) OR (OLD.unit_cost <> NEW.unit_cost) THEN
        INSERT INTO solving_inventory.Product_Price_History (
            product_id,
            old_cost,
            new_cost,
            old_price,
            new_price,
            changed_by
        ) VALUES (
            NEW.product_id,
            OLD.unit_cost,
            NEW.unit_cost,
            OLD.unit_price,
            NEW.unit_price,
            CURRENT_USER
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_product_price_history
AFTER UPDATE OF unit_price, unit_cost ON solving_inventory.Products
FOR EACH ROW
EXECUTE FUNCTION solving_inventory.track_price_changes();

-- End of Triggers and Stored Procedures Script
