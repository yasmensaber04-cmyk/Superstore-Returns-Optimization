/* =============================================================================
PROJECT: Superstore Sales & Returns Analysis
DOCUMENT: 00_Data_Modeling_and_ETL.sql
PURPOSE: Build a Star Schema by creating Dimension and Fact tables.
============================================================================= */

-----------------------------------------------------------
-- 1. PREPARE DIMENSION TABLES
-----------------------------------------------------------

-- A. Create and Populate Dim_Customer
DROP TABLE IF EXISTS Dim_Customer;
CREATE TABLE Dim_Customer (
    Customer_Key INT PRIMARY KEY IDENTITY(1,1),
    Customer_Name NVARCHAR(255),
    Customer_Segment NVARCHAR(50)
);

INSERT INTO Dim_Customer (Customer_Name, Customer_Segment)
SELECT [Customer_Name], MAX([Customer_Segment]) 
FROM Orders 
GROUP BY [Customer_Name];


-- B. Create and Populate Dim_Manager
DROP TABLE IF EXISTS Dim_Manager;
CREATE TABLE Dim_Manager (
    Manager_Key INT PRIMARY KEY IDENTITY(1,1), 
    Manager_Name NVARCHAR(255), 
    Region_Group NVARCHAR(50)
);

INSERT INTO Dim_Manager (Manager_Name, Region_Group) 
SELECT MAX([column2]), [column1] 
FROM Users 
WHERE [column1] <> 'Region' 
GROUP BY [column1];


-- C. Create and Populate Dim_Product
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
SELECT [Product_Name], MAX([Product_Category]), MAX([Product_Sub_Category]), MAX([Product_Container]), MAX([Product_Base_Margin]) 
FROM Orders 
GROUP BY [Product_Name];


-- D. Create and Populate Dim_Returns
DROP TABLE IF EXISTS Dim_Returns;
CREATE TABLE Dim_Returns (
    Return_Key INT PRIMARY KEY IDENTITY(1,1), 
    Order_ID NVARCHAR(255), 
    Return_Status NVARCHAR(50)
);

INSERT INTO Dim_Returns (Order_ID, Return_Status) 
SELECT [Order_ID], [Status] 
FROM Returns;

-----------------------------------------------------------
-- 2. CREATE THE CENTRAL FACT TABLE (Fact_Sales)
-----------------------------------------------------------

DROP TABLE IF EXISTS Fact_Sales;
CREATE TABLE Fact_Sales (
    Sales_ID INT PRIMARY KEY IDENTITY(1,1),
    Order_ID NVARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Order_Priority NVARCHAR(50),
    Ship_Mode NVARCHAR(50),
    Customer_Key INT, 
    Manager_Key INT,
    Product_Key INT,
    Return_Key INT,
    Sales FLOAT,
    Profit FLOAT,
    Order_Quantity INT,
    Discount DECIMAL(18,10),
    Shipping_Cost FLOAT
);

-----------------------------------------------------------
-- 3. LOAD DATA INTO FACT TABLE (Smart Joining)
-----------------------------------------------------------

INSERT INTO Fact_Sales (
    Order_ID, Order_Date, Ship_Date, Order_Priority, Ship_Mode, 
    Customer_Key, Manager_Key, Product_Key, Return_Key, 
    Sales, Profit, Order_Quantity, Discount, Shipping_Cost
)
SELECT 
    o.[Order_ID], 
    o.[Order_Date], 
    o.[Ship_Date], 
    o.[Order_Priority], 
    o.[Ship_Mode],
    Dim_Customer.Customer_Key,
    Dim_Manager.Manager_Key, 
    Dim_Product.Product_Key, 
    Dim_Returns.Return_Key,
    o.[Sales], 
    o.[Profit], 
    o.[Order_Quantity], 
    o.[Discount], 
    o.[Shipping_Cost]
FROM Orders AS o
LEFT JOIN Dim_Customer ON o.Customer_Name = Dim_Customer.Customer_Name
LEFT JOIN Dim_Manager ON Dim_Manager.Region_Group = (
    CASE 
        WHEN o.Region IN ('Ontario') THEN 'Central'
        WHEN o.Region IN ('Atlantic', 'Quebec', 'Nunavut') THEN 'East'
        WHEN o.Region IN ('Prairie', 'West', 'Yukon', 'Northwest Territories') THEN 'West'
        ELSE 'South' 
    END
)
LEFT JOIN Dim_Product ON o.[Product_Name] = Dim_Product.Product_Name
LEFT JOIN Dim_Returns ON o.[Order_ID] = Dim_Returns.Order_ID;

-----------------------------------------------------------
-- 4. FINAL VALIDATION
-----------------------------------------------------------
SELECT 'Success!' AS Execution_Status, COUNT(*) AS Total_Sales_Rows FROM Fact_Sales;
