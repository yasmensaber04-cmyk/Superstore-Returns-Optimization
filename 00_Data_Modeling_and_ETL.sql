/* =============================================================================
PROJECT: Superstore Sales & Returns Analysis
STAGE: Phase 1 - Data Modeling & ETL (Extract, Transform, Load)
PURPOSE: Transforming raw flat files into a clean Star Schema for BI reporting.
AUTHOR: [Yasmen Saber]
=============================================================================
*/

-----------------------------------------------------------
-- 1. PREPARING DIMENSION TABLES
-----------------------------------------------------------

-- A. Create & Populate Dim_Manager (Unique Managers per Region)
DROP TABLE IF EXISTS Dim_Manager;
CREATE TABLE Dim_Manager (
    Manager_Key INT PRIMARY KEY IDENTITY(1,1),
    Manager_Name NVARCHAR(255),
    Region_Group NVARCHAR(50)
);

INSERT INTO Dim_Manager (Manager_Name, Region_Group)
SELECT 
    MAX([column2]) AS Manager_Name, 
    [column1] AS Region_Group
FROM Users
WHERE [column1] <> 'Region'
GROUP BY [column1];


-- B. Create & Populate Dim_Product (Ensuring unique products by name)
DROP TABLE IF EXISTS Dim_Product;
CREATE TABLE Dim_Product (
    Product_Key INT PRIMARY KEY IDENTITY(1,1),
    Product_Name NVARCHAR(MAX),
    Category NVARCHAR(255),
    Sub_Category NVARCHAR(255),
    Product_Container NVARCHAR(100),
    Product_Base_Margin FLOAT
);

INSERT INTO Dim_Product (Product_Name, Category, Sub_Category, Product_Container, Product_Base_Margin)
SELECT 
    [Product_Name], 
    MAX([Product_Category]), 
    MAX([Product_Sub_Category]),
    MAX([Product_Container]),
    MAX([Product_Base_Margin])
FROM Orders
GROUP BY [Product_Name];


-- C. Create & Populate Dim_Returns (Lookup for returned orders)
DROP TABLE IF EXISTS Dim_Returns;
CREATE TABLE Dim_Returns (
    Return_Key INT PRIMARY KEY IDENTITY(1,1),
    Order_ID NVARCHAR(255),
    Return_Status NVARCHAR(50)
);

INSERT INTO Dim_Returns (Order_ID, Return_Status)
SELECT [Order_ID], [Status] FROM Returns;

-----------------------------------------------------------
-- 2. CREATING THE CENTRAL FACT TABLE (Fact_Sales)
-----------------------------------------------------------

DROP TABLE IF EXISTS Fact_Sales;
CREATE TABLE Fact_Sales (
    Sales_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID NVARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Order_Priority NVARCHAR(50),
    Ship_Mode NVARCHAR(50),
    Customer_Segment NVARCHAR(50),
    Manager_Key INT,
    Product_Key INT,
    Return_Key INT,
    Sales FLOAT,
    Profit FLOAT,
    Order_Quantity INT,
    Discount DECIMAL(18,10),
    Shipping_Cost FLOAT
);

-- Mapping logic and population
INSERT INTO Fact_Sales (
    Order_ID, Order_Date, Ship_Date, Order_Priority, Ship_Mode, 
    Customer_Segment, Manager_Key, Product_Key, Return_Key, 
    Sales, Profit, Order_Quantity, Discount, Shipping_Cost
)
SELECT 
    o.[Order_ID], 
    o.[Order_Date], 
    o.[Ship_Date], 
    o.[Order_Priority], 
    o.[Ship_Mode],
    o.[Customer_Segment], 
    m.Manager_Key, 
    p.Product_Key, 
    r.Return_Key,
    o.[Sales], 
    o.[Profit], 
    o.[Order_Quantity], 
    o.[Discount], 
    o.[Shipping_Cost]
FROM Orders o
LEFT JOIN Dim_Manager m ON m.Region_Group = (
    CASE 
        WHEN o.Region IN ('Ontario') THEN 'Central'
        WHEN o.Region IN ('Atlantic', 'Quebec', 'Nunavut') THEN 'East'
        WHEN o.Region IN ('Prairie', 'West', 'Yukon', 'Northwest Territories') THEN 'West'
        ELSE 'South' 
    END
)
LEFT JOIN Dim_Product p ON o.[Product_Name] = p.Product_Name
LEFT JOIN Dim_Returns r ON o.[Order_ID] = r.Order_ID;

-----------------------------------------------------------
-- 3. FINAL INTEGRITY CHECK (Data Validation)
-----------------------------------------------------------

SELECT 'Raw Orders Table' AS Table_Name, COUNT(*) AS Row_Count FROM Orders
UNION ALL
SELECT 'Final Fact_Sales Table' AS Table_Name, COUNT(*) AS Row_Count FROM Fact_Sales;
