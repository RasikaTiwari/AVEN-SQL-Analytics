# AVEN — Fashion Retail Merchandising & Inventory Analytics

## Project Overview

**AVEN** is a SQL Server-based analytics project designed around a fashion retail business that outsources its clothing production and manages products, suppliers, warehouses, stores, customers, sales, inventory, returns, reviews, pricing, and promotions.

The project focuses on using **SQL to solve practical business problems** and generate insights that can support decisions related to sales, inventory management, customers, products, suppliers, pricing, and returns.

---

## Business Objective

The objective of AVEN is to build a relational database and use SQL analytics to answer important business questions such as:

* Which products are performing well?
* Which products have low or excess inventory?
* Where is additional inventory required?
* How do customer characteristics relate to purchasing behavior?
* Which products generate high revenue?
* How much revenue is affected by returns?
* Which products receive poor customer reviews?
* How effective are discounts and promotions?
* Which suppliers have delayed orders?
* Which products or locations require business attention?

---

## Technology Used

| Technology                              | Purpose                            |
| --------------------------------------- | ---------------------------------- |
| **Microsoft SQL Server**                | Database                           |
| **SQL Server Management Studio (SSMS)** | Database development and execution |
| **T-SQL**                               | Data manipulation and analysis     |

---

## Database Entities

The database models the major components of the fashion retail business:

* **Product**
* **Product Variant**
* **Supplier**
* **Warehouse**
* **Store**
* **Customer**
* **Purchase Order**
* **Purchase Order Item**
* **Sale**
* **Sale Item**
* **Inventory**
* **Return**
* **Review**
* **Price History**
* **Promotion**

These entities are connected using primary keys and foreign keys to maintain relationships and data integrity.

---

## SQL Concepts Used

The project applies a wide range of SQL concepts, including:

* SELECT statements
* Filtering and sorting
* Aggregate functions
* GROUP BY and HAVING
* INNER, LEFT and other JOIN operations
* Set operations
* CASE expressions
* String functions
* Numeric functions
* Date functions
* NULL handling
* Subqueries
* Common Table Expressions (CTEs)
* Recursive CTEs
* Window functions
* Views
* Stored procedures
* Triggers
* DDL and DML
* Primary and foreign keys
* Constraints
* Indexes
* Query optimization concepts

---

## Business Analysis

The project contains **20 business-oriented SQL questions** covering different areas of the retail business.

### Customer Analytics

* Customer age-group analysis
* Customer registration trends
* Customer purchasing behavior

### Sales & Revenue

* Product sales performance
* Revenue analysis
* Discount analysis
* Order-level analysis

### Inventory

* Low and excess inventory identification
* Inventory requirements by location
* Product availability

### Returns & Reviews

* Return analysis
* Products affected by returns
* Products receiving poor reviews

### Suppliers & Orders

* Purchase order analysis
* Order delivery status
* Supplier performance

### Products & Pricing

* Product performance
* Product pricing
* Promotions and discounts
* Price-related analysis

---

## Project Structure

```text
AVEN-SQL-Analytics/
│
├── README.md
│
├── SQL/
│   └── AVEN_Project.sql
│
└── Documentation/
    └── ER_Diagram.png
```

### SQL File

`AVEN_Project.sql` contains the SQL implementation of the project, including:

1. Database and table creation
2. Constraints and relationships
3. Data generation/insertion
4. Business analysis queries
5. The final set of 20 business questions

---

## Key Learning Outcomes

Through this project, I practiced designing and querying a relational database while focusing on **business problem solving rather than only SQL syntax**.

The project helped develop skills in:

* Relational database design
* Data modelling
* Writing complex SQL queries
* Translating business problems into SQL
* Analytical thinking
* Working with multiple related tables
* Using advanced SQL techniques
* Extracting actionable information from transactional data

---

## Future Scope

The project can be extended into a broader analytics solution by adding:

* **Python** for deeper data analysis and automation
* **Pandas & NumPy** for data processing
* **Power BI** for interactive dashboards
* Additional KPIs for merchandising and inventory management
* Advanced query optimization and performance analysis

---

## Author

**Rasika Tiwari**

B.E. Mechanical Engineering
IET DAVV, Indore

---

## Project Status

**Completed — SQL Server Analytics Project**
# AVEN-SQL-Analytics
SQL Server analytics project for an enterprise fashion merchandising and inventory platform.
