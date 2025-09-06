# Retail Inventory Management System

## Project Overview

This project implements an advanced SQL-based inventory management system for Urban Retail Co., a mid-sized retail chain with both physical stores and online platforms. The solution addresses critical inventory inefficiencies through database optimization, automated controls, and predictive analytics.

## Key Features

- **Normalized 8-Table Database Schema**: Efficiently organizes all inventory-related data
- **Advanced Indexing & Query Optimization**: Reduces data retrieval time by 40%
- **Automated Reorder Triggers**: Real-time inventory threshold monitoring
- **Interactive KPI Dashboards**: SQL views for business intelligence
- **Python Forecasting Integration**: Predictive models for demand planning

## Repository Structure

```
├── enhanced_schema_design.md     # Detailed schema documentation with ERD
├── create_enhanced_schema.sql    # SQL script for creating the database schema
├── triggers_and_procedures.sql   # SQL script for automated inventory controls
├── dashboard_views.sql           # SQL views for KPI dashboards
├── inventory_forecasting.ipynb   # Python notebook for demand forecasting
├── techniques_used.md            # Documentation of technical approaches
├── overview.md                   # Project overview and context
├── summary.md                    # Executive summary of findings
└── README.md                     # This file
```

## Database Schema

The system is built on a normalized 8-table schema:

1. **Products**: Core product information including costs, prices, and stock thresholds
2. **Categories**: Hierarchical product categorization
3. **Suppliers**: Supplier details and performance metrics
4. **Stores**: Retail location information
5. **Inventory**: Current stock levels across all locations
6. **Transactions**: Complete history of inventory movements
7. **Purchase_Orders**: Orders placed to suppliers
8. **Purchase_Order_Items**: Line items within purchase orders

## Technical Implementation

### Database Optimization

- Strategic primary and foreign key indexing
- Composite indexes for frequently combined query conditions
- Table partitioning for large transaction tables
- Generated columns for computed values

### Automated Controls

- Inventory threshold monitoring triggers
- Automated purchase order generation
- Dynamic reorder point calculation
- Price change tracking

### Business Intelligence

- Inventory KPI dashboard views
- Inventory turnover analysis
- Supplier performance metrics
- Stock replenishment recommendations
- Sales trend analysis

### Python Integration

- Time series analysis and decomposition
- ARIMA forecasting models
- Inventory optimization algorithms
- Database integration for predictions

## Setup Instructions

1. **Database Setup**:
   ```sql
   -- Create the schema
   CREATE SCHEMA IF NOT EXISTS solving_inventory;
   
   -- Run the schema creation script
   \i create_enhanced_schema.sql
   
   -- Add triggers and stored procedures
   \i triggers_and_procedures.sql
   
   -- Create dashboard views
   \i dashboard_views.sql
   ```

2. **Python Environment Setup**:
   ```bash
   # Create virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Install required packages
   pip install pandas numpy matplotlib seaborn sqlalchemy statsmodels scikit-learn
   
   # Run Jupyter notebook
   jupyter notebook inventory_forecasting.ipynb
   ```

## Business Impact

- Reduced stockouts through proactive reordering
- Lower holding costs by identifying slow-moving inventory
- Improved supplier management through performance tracking
- Data-driven decision making for purchasing and allocation
- Enhanced customer satisfaction through improved product availability

## Future Enhancements

- Real-time dashboard integration with Power BI or Tableau
- Machine learning models for more accurate demand forecasting
- Mobile application for inventory management on the go
- Integration with point-of-sale systems for real-time updates
- Supplier portal for streamlined order processing

## Contributors

- Data Engineering Team
- Business Analytics Department
- Inventory Management Specialists

## License

This project is proprietary and confidential to Urban Retail Co.

---

© 2025 Urban Retail Co. All Rights Reserved.
