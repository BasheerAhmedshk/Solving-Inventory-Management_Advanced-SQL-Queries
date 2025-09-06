# Executive Summary: Solving Inventory Inefficiencies for Urban Retail Co.

**Date:** June 2, 2025

**Project:** Leveraging Advanced SQL Analytics for Inventory Optimization

## Introduction

Urban Retail Co., a growing mid-sized retail chain, faces significant challenges in managing its inventory across physical and online platforms. Current reactive and manual processes, coupled with underutilized data, lead to frequent stockouts of popular items and overstocking of slow-moving goods. These inefficiencies result in missed sales opportunities, poor customer experiences, inflated warehousing costs, and tied-up working capital. This project aimed to address these issues by designing and demonstrating a SQL-driven inventory monitoring and optimization solution, transforming raw transactional and inventory data into actionable business intelligence.

## Methodology

Our approach focused on applying data analysis principles and database best practices to the provided `retail_store_inventory.csv` dataset. Key steps included:

1.  **Data Understanding:** Analyzing the structure and content of the raw dataset, which contained daily snapshots of inventory levels, sales, orders, pricing, and contextual factors (weather, promotions) for various products across different stores and regions.
2.  **Database Design:** Developing a normalized relational database schema (`solving_inventory`) consisting of `Products`, `Stores`, and `InventorySnapshots` tables. This design reduces data redundancy, improves integrity, and optimizes query performance. An Entity Relationship Diagram (ERD) was created to visualize the schema.
3.  **SQL Scripting:** Generating foundational SQL scripts (within `create_schema.sql`) for creating the schema, tables, defining relationships (primary/foreign keys), and implementing indexes for efficient data retrieval.
4.  **KPI Analysis & Reporting:** Simulating the analysis process using Python (in `inventory_analysis.ipynb`) to calculate key performance indicators (KPIs) and generate insights. This included analyzing stock levels, sales trends, inventory turnover (approximated), identifying fast/slow-moving products, estimating stockout rates, and calculating basic reorder points. While direct SQL execution was not performed per constraints, the Python notebook outlines the analytical logic that would typically leverage the SQL database.

## Key Findings

Our analysis of the inventory data revealed several critical areas for improvement:

1.  **Inventory Imbalances:** Significant variations exist in inventory levels across products and stores. Analysis identified numerous instances of potential overstocking (indicated by low sales velocity for items with high inventory) and stockouts (approximated by zero inventory despite positive sales on a given day).
2.  **Sales Velocity Disparities:** A clear distinction exists between fast-moving and slow-moving products. A substantial portion of products falls into the slow-moving category (e.g., below the 25th percentile of sales volume), contributing disproportionately to holding costs.
3.  **Stockout Occurrences:** The approximated stockout rate suggests that opportunities for sales are being missed due to insufficient stock of certain items at specific times. While the exact financial impact requires deeper analysis (linking stockouts to lost sales value), the frequency indicates a systemic issue in replenishment or forecasting.
4.  **Inventory Turnover:** The approximated inventory turnover ratio highlights potential inefficiencies in capital utilization. A lower turnover suggests that capital is tied up in inventory for longer periods, particularly for slow-moving items.
5.  **Reorder Point Gaps:** A simple reorder point estimation revealed numerous product-store combinations currently operating below suggested minimum stock levels, increasing the immediate risk of stockouts.
6.  **Data Granularity:** The dataset provides rich contextual information (weather, promotions, seasonality, competitor pricing) that, while explored briefly, offers significant potential for more advanced predictive modeling of demand.

## Recommendations

Based on these findings, we propose the following actionable recommendations for Urban Retail Co.:

1.  **Implement the Normalized Database:** Transition from flat-file analysis to utilizing the designed `solving_inventory` SQL database. This will provide a robust, scalable foundation for all future inventory analysis and reporting.
2.  **Refine Reorder Point Calculation:** Move beyond simple averages. Implement dynamic reorder points calculated per product/store combination, incorporating actual lead times, demand variability (standard deviation of sales), and desired service levels. Set up automated alerts for inventory falling below these points.
3.  **Active Management of Slow-Moving Stock:** Develop and implement clear strategies for products identified as slow-movers. Options include targeted promotions, bundling with faster-moving items, evaluating potential price reductions, or, in persistent cases, considering delisting to free up capital and warehouse space.
4.  **Investigate and Mitigate Stockouts:** For frequently stocked-out items (fast-movers), perform root cause analysis. Is it inaccurate forecasting, unreliable supplier lead times, or insufficient safety stock? Adjust safety stock levels and review supplier performance based on findings.
5.  **Enhance Demand Forecasting:** Leverage the historical data and contextual factors within the SQL database to build more sophisticated demand forecasting models (e.g., ARIMA, Prophet). Accurate forecasts are crucial for optimizing both purchasing and stock allocation across stores and regions.
6.  **Develop KPI Dashboards:** Create dynamic dashboards (using tools like Power BI, Tableau, or custom web applications fed by the SQL database) to provide real-time visibility into key inventory metrics (Turnover, Stockout Rate, Inventory Value, Days of Supply, Fast/Slow Mover status) for managers at store, regional, and central levels.

## Expected Business Impact

By implementing these recommendations, Urban Retail Co. can expect significant improvements in operational efficiency and profitability:

*   **Reduced Stockouts:** Leading to increased sales and improved customer satisfaction.
*   **Lower Holding Costs:** By actively managing and reducing overstock, particularly of slow-moving items.
*   **Optimized Working Capital:** Freeing up capital previously tied in excess inventory.
*   **Improved Decision Making:** Enabling proactive, data-driven inventory management instead of reactive adjustments.
*   **Enhanced Supply Chain Efficiency:** Through better forecasting and potentially improved supplier negotiations based on performance data.

This project provides the foundational schema and analytical direction for Urban Retail Co. to transform its inventory management practices, leveraging data as a strategic asset to drive growth and profitability.
