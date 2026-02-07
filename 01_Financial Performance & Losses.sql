-- 1. Top 5 Loss-Making Products by Region
SELECT TOP 5 
    p.Category, 
    p.Product_Name, 
    m.Region_Group,
    SUM(f.Sales) AS Total_Sales,
    SUM(f.Profit) AS Total_Loss
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Key = p.Product_Key
JOIN Dim_Manager m ON f.Manager_Key = m.Manager_Key
WHERE f.Profit < 0
GROUP BY p.Category, p.Product_Name, m.Region_Group
ORDER BY Total_Loss ASC; -- Showing the highest loss first

-- 2. Return Analysis and Lost Revenue by Manager
SELECT 
    p.Category,
    m.Manager_Name,
    COUNT(f.Return_Key) AS Return_Count,
    SUM(f.Sales) AS Lost_Sales_Value
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Key = p.Product_Key
JOIN Dim_Manager m ON f.Manager_Key = m.Manager_Key
JOIN Dim_Returns r ON f.Return_Key = r.Return_Key
GROUP BY p.Category, m.Manager_Name
ORDER BY Return_Count DESC;

-- 3. Average Shipping Duration by Order Priority
SELECT 
    Order_Priority, 
    AVG(DATEDIFF(day, Order_Date, Ship_Date)) AS Avg_Shipping_Days
FROM Fact_Sales
GROUP BY Order_Priority
ORDER BY Avg_Shipping_Days DESC;
