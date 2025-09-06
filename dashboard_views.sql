-- SQL Views for KPI Dashboards
-- Designed for Urban Retail Co. Inventory Management System

-- Set the search path to the schema
SET search_path TO solving_inventory;

-- -----------------------------------------------------
-- View: Inventory_KPI_Dashboard
-- Purpose: Provides key inventory metrics for dashboard visualization
-- -----------------------------------------------------
CREATE OR REPLACE VIEW solving_inventory.vw_inventory_kpi_dashboard AS
SELECT
    s.region,
    s.store_id,
    s.store_name,
    c.category_id,
    c.category_name,
    COUNT(DISTINCT i.product_id) AS total_products,
    SUM(i.quantity_on_hand) AS total_units_on_hand,
    SUM(i.quantity_on_hand * p.unit_cost) AS total_inventory_value,
    SUM(CASE WHEN i.quantity_on_hand <= p.min_stock_level THEN 1 ELSE 0 END) AS low_stock_count,
    SUM(CASE WHEN i.quantity_on_hand = 0 THEN 1 ELSE 0 END) AS stockout_count,
    SUM(CASE WHEN i.quantity_on_hand >= p.max_stock_level THEN 1 ELSE 0 END) AS overstock_count,
    ROUND(AVG(i.quantity_on_hand), 2) AS avg_units_per_product,
    CURRENT_DATE AS report_date
FROM
    solving_inventory.Inventory i
JOIN
    solving_inventory.Products p ON i.product_id = p.product_id
JOIN
    solving_inventory.Categories c ON p.category_id = c.category_id
JOIN
    solving_inventory.Stores s ON i.store_id = s.store_id
GROUP BY
    s.region, s.store_id, s.store_name, c.category_id, c.category_name
WITH DATA;

COMMENT ON VIEW solving_inventory.vw_inventory_kpi_dashboard IS 'Provides key inventory metrics for dashboard visualization';

-- -----------------------------------------------------
-- View: Inventory_Turnover_Analysis
-- Purpose: Calculates inventory turnover metrics by product, category, and store
-- -----------------------------------------------------
CREATE OR REPLACE VIEW solving_inventory.vw_inventory_turnover_analysis AS
WITH sales_data AS (
    SELECT
        t.store_id,
        t.product_id,
        SUM(t.quantity) AS units_sold,
        SUM(t.total_amount) AS sales_revenue,
        MIN(t.transaction_date) AS first_sale_date,
        MAX(t.transaction_date) AS last_sale_date,
        COUNT(DISTINCT DATE(t.transaction_date)) AS days_with_sales
    FROM
        solving_inventory.Transactions t
    WHERE
        t.transaction_type = 'SALE'
        AND t.transaction_date >= (CURRENT_DATE - INTERVAL '90 days')
    GROUP BY
        t.store_id, t.product_id
)
SELECT
    s.region,
    s.store_id,
    s.store_name,
    p.product_id,
    p.product_name,
    c.category_name,
    i.quantity_on_hand AS current_stock,
    COALESCE(sd.units_sold, 0) AS units_sold_90days,
    CASE 
        WHEN i.quantity_on_hand > 0 AND COALESCE(sd.units_sold, 0) > 0 
        THEN ROUND((COALESCE(sd.units_sold, 0) / i.quantity_on_hand), 2)
        ELSE 0 
    END AS turnover_ratio_90days,
    CASE
        WHEN COALESCE(sd.units_sold, 0) > 0 AND COALESCE(sd.days_with_sales, 0) > 0
        THEN ROUND((COALESCE(sd.units_sold, 0) / COALESCE(sd.days_with_sales, 1)), 2)
        ELSE 0
    END AS avg_daily_sales,
    CASE
        WHEN COALESCE(sd.units_sold, 0) > 0
        THEN ROUND((i.quantity_on_hand / (COALESCE(sd.units_sold, 1) / 90.0)), 0)
        ELSE NULL
    END AS days_of_supply,
    COALESCE(sd.sales_revenue, 0) AS sales_revenue_90days,
    (i.quantity_on_hand * p.unit_cost) AS inventory_value,
    CASE
        WHEN (i.quantity_on_hand * p.unit_cost) > 0 AND COALESCE(sd.sales_revenue, 0) > 0
        THEN ROUND((COALESCE(sd.sales_revenue, 0) / (i.quantity_on_hand * p.unit_cost)), 2)
        ELSE 0
    END AS revenue_to_investment_ratio,
    COALESCE(sd.last_sale_date, NULL) AS last_sale_date,
    CASE
        WHEN sd.last_sale_date IS NOT NULL
        THEN CURRENT_DATE - sd.last_sale_date::date
        ELSE NULL
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
    sales_data sd ON i.store_id = sd.store_id AND i.product_id = sd.product_id
WHERE
    i.quantity_on_hand > 0
WITH DATA;

COMMENT ON VIEW solving_inventory.vw_inventory_turnover_analysis IS 'Calculates inventory turnover metrics by product, category, and store';

-- -----------------------------------------------------
-- View: Supplier_Performance_Dashboard
-- Purpose: Analyzes supplier performance metrics for decision making
-- -----------------------------------------------------
CREATE OR REPLACE VIEW solving_inventory.vw_supplier_performance_dashboard AS
WITH po_metrics AS (
    SELECT
        po.supplier_id,
        COUNT(po.po_id) AS total_orders,
        SUM(CASE WHEN po.status = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
        SUM(CASE WHEN po.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_orders,
        AVG(CASE 
            WHEN po.status = 'DELIVERED' AND po.actual_delivery_date IS NOT NULL AND po.expected_delivery_date IS NOT NULL
            THEN (po.actual_delivery_date - po.expected_delivery_date)
            ELSE NULL
        END) AS avg_delivery_delay_days,
        SUM(CASE 
            WHEN po.status = 'DELIVERED' AND po.actual_delivery_date <= po.expected_delivery_date
            THEN 1 ELSE 0
        END) AS on_time_deliveries,
        SUM(po.total_amount) AS total_order_value
    FROM
        solving_inventory.Purchase_Orders po
    WHERE
        po.order_date >= (CURRENT_DATE - INTERVAL '180 days')
    GROUP BY
        po.supplier_id
)
SELECT
    s.supplier_id,
    s.supplier_name,
    s.performance_rating,
    s.is_active,
    COALESCE(pm.total_orders, 0) AS total_orders_180days,
    COALESCE(pm.delivered_orders, 0) AS delivered_orders,
    COALESCE(pm.cancelled_orders, 0) AS cancelled_orders,
    CASE 
        WHEN COALESCE(pm.total_orders, 0) > 0
        THEN ROUND((COALESCE(pm.delivered_orders, 0)::DECIMAL / COALESCE(pm.total_orders, 1)) * 100, 2)
        ELSE 0
    END AS fulfillment_rate_pct,
    CASE 
        WHEN COALESCE(pm.delivered_orders, 0) > 0
        THEN ROUND((COALESCE(pm.on_time_deliveries, 0)::DECIMAL / COALESCE(pm.delivered_orders, 1)) * 100, 2)
        ELSE 0
    END AS on_time_delivery_pct,
    COALESCE(pm.avg_delivery_delay_days, 0) AS avg_delivery_delay_days,
    COALESCE(pm.total_order_value, 0) AS total_order_value_180days
FROM
    solving_inventory.Suppliers s
LEFT JOIN
    po_metrics pm ON s.supplier_id = pm.supplier_id
WITH DATA;

COMMENT ON VIEW solving_inventory.vw_supplier_performance_dashboard IS 'Analyzes supplier performance metrics for decision making';

-- -----------------------------------------------------
-- View: Stock_Replenishment_Recommendations
-- Purpose: Provides actionable recommendations for inventory replenishment
-- -----------------------------------------------------
CREATE OR REPLACE VIEW solving_inventory.vw_stock_replenishment_recommendations AS
WITH sales_velocity AS (
    SELECT
        t.store_id,
        t.product_id,
        SUM(t.quantity) AS total_units_sold,
        COUNT(DISTINCT DATE(t.transaction_date)) AS days_with_sales,
        CASE
            WHEN COUNT(DISTINCT DATE(t.transaction_date)) > 0
            THEN ROUND(SUM(t.quantity) / COUNT(DISTINCT DATE(t.transaction_date)), 2)
            ELSE 0
        END AS avg_daily_sales
    FROM
        solving_inventory.Transactions t
    WHERE
        t.transaction_type = 'SALE'
        AND t.transaction_date >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY
        t.store_id, t.product_id
),
pending_orders AS (
    SELECT
        po.store_id,
        poi.product_id,
        SUM(poi.quantity_ordered - poi.quantity_received) AS units_on_order
    FROM
        solving_inventory.Purchase_Order_Items poi
    JOIN
        solving_inventory.Purchase_Orders po ON poi.po_id = po.po_id
    WHERE
        poi.status IN ('PENDING', 'PARTIAL')
        AND po.status IN ('SUBMITTED', 'CONFIRMED', 'SHIPPED')
    GROUP BY
        po.store_id, poi.product_id
)
SELECT
    s.region,
    s.store_id,
    s.store_name,
    p.product_id,
    p.product_name,
    c.category_name,
    i.quantity_on_hand AS current_stock,
    p.min_stock_level AS reorder_point,
    p.max_stock_level AS max_stock_level,
    COALESCE(sv.avg_daily_sales, 0) AS avg_daily_sales,
    p.lead_time_days,
    COALESCE(po.units_on_order, 0) AS units_on_order,
    CASE
        WHEN i.quantity_on_hand <= p.min_stock_level AND COALESCE(po.units_on_order, 0) = 0
        THEN 'REORDER_NEEDED'
        WHEN i.quantity_on_hand = 0
        THEN 'STOCKOUT'
        WHEN i.quantity_on_hand <= p.min_stock_level AND COALESCE(po.units_on_order, 0) > 0
        THEN 'ORDER_PENDING'
        WHEN i.quantity_on_hand > p.max_stock_level
        THEN 'OVERSTOCK'
        ELSE 'ADEQUATE'
    END AS stock_status,
    CASE
        WHEN i.quantity_on_hand <= p.min_stock_level AND COALESCE(po.units_on_order, 0) = 0
        THEN GREATEST(p.max_stock_level - i.quantity_on_hand, 
                     CEIL(COALESCE(sv.avg_daily_sales, 1) * p.lead_time_days * 1.5))
        ELSE 0
    END AS recommended_order_quantity,
    CASE
        WHEN COALESCE(sv.avg_daily_sales, 0) > 0
        THEN ROUND(i.quantity_on_hand / COALESCE(sv.avg_daily_sales, 1), 0)
        ELSE NULL
    END AS days_of_supply
FROM
    solving_inventory.Inventory i
JOIN
    solving_inventory.Products p ON i.product_id = p.product_id
JOIN
    solving_inventory.Categories c ON p.category_id = c.category_id
JOIN
    solving_inventory.Stores s ON i.store_id = s.store_id
LEFT JOIN
    sales_velocity sv ON i.store_id = sv.store_id AND i.product_id = sv.product_id
LEFT JOIN
    pending_orders po ON i.store_id = po.store_id AND i.product_id = po.product_id
WITH DATA;

COMMENT ON VIEW solving_inventory.vw_stock_replenishment_recommendations IS 'Provides actionable recommendations for inventory replenishment';

-- -----------------------------------------------------
-- View: Sales_Trend_Analysis
-- Purpose: Analyzes sales trends over time for forecasting
-- -----------------------------------------------------
CREATE OR REPLACE VIEW solving_inventory.vw_sales_trend_analysis AS
WITH daily_sales AS (
    SELECT
        DATE(t.transaction_date) AS sale_date,
        t.store_id,
        s.region,
        t.product_id,
        p.category_id,
        SUM(t.quantity) AS units_sold,
        SUM(t.total_amount) AS sales_revenue
    FROM
        solving_inventory.Transactions t
    JOIN
        solving_inventory.Products p ON t.product_id = p.product_id
    JOIN
        solving_inventory.Stores s ON t.store_id = s.store_id
    WHERE
        t.transaction_type = 'SALE'
        AND t.transaction_date >= (CURRENT_DATE - INTERVAL '365 days')
    GROUP BY
        DATE(t.transaction_date), t.store_id, s.region, t.product_id, p.category_id
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', sale_date) AS month_start,
        store_id,
        region,
        product_id,
        category_id,
        SUM(units_sold) AS monthly_units_sold,
        SUM(sales_revenue) AS monthly_revenue,
        COUNT(DISTINCT sale_date) AS days_with_sales
    FROM
        daily_sales
    GROUP BY
        DATE_TRUNC('month', sale_date), store_id, region, product_id, category_id
)
SELECT
    ms.month_start,
    s.store_id,
    s.store_name,
    s.region,
    p.product_id,
    p.product_name,
    c.category_id,
    c.category_name,
    ms.monthly_units_sold,
    ms.monthly_revenue,
    ROUND(ms.monthly_units_sold / NULLIF(ms.days_with_sales, 0), 2) AS avg_daily_units,
    ROUND(ms.monthly_revenue / NULLIF(ms.days_with_sales, 0), 2) AS avg_daily_revenue,
    LAG(ms.monthly_units_sold) OVER (
        PARTITION BY ms.store_id, ms.product_id 
        ORDER BY ms.month_start
    ) AS prev_month_units,
    CASE
        WHEN LAG(ms.monthly_units_sold) OVER (
            PARTITION BY ms.store_id, ms.product_id 
            ORDER BY ms.month_start
        ) > 0
        THEN ROUND(
            (ms.monthly_units_sold - LAG(ms.monthly_units_sold) OVER (
                PARTITION BY ms.store_id, ms.product_id 
                ORDER BY ms.month_start
            )) / LAG(ms.monthly_units_sold) OVER (
                PARTITION BY ms.store_id, ms.product_id 
                ORDER BY ms.month_start
            ) * 100, 2
        )
        ELSE NULL
    END AS month_over_month_pct_change
FROM
    monthly_sales ms
JOIN
    solving_inventory.Stores s ON ms.store_id = s.store_id
JOIN
    solving_inventory.Products p ON ms.product_id = p.product_id
JOIN
    solving_inventory.Categories c ON ms.category_id = c.category_id
ORDER BY
    ms.month_start DESC, s.region, c.category_name, p.product_name
WITH DATA;

COMMENT ON VIEW solving_inventory.vw_sales_trend_analysis IS 'Analyzes sales trends over time for forecasting';

-- End of SQL Views Script
