-- 1. Return Frequency by Shipping Mode and Container Type
SELECT 
    f.Ship_Mode,
    p.Product_Container,
    COUNT(f.Return_Key) AS Returns_Count
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Key = p.Product_Key
WHERE f.Return_Key IS NOT NULL
GROUP BY f.Ship_Mode, p.Product_Container
ORDER BY Returns_Count DESC;

-- 2. Return Rate Percentage by Logistics Configuration
SELECT 
    f.Ship_Mode,
    p.Product_Container,
    COUNT(f.Sales_ID) AS Total_Orders,
    COUNT(f.Return_Key) AS Returns_Count,
    (CAST(COUNT(f.Return_Key) AS FLOAT) / COUNT(f.Sales_ID)) * 100 AS Return_Rate
FROM Fact_Sales f
JOIN Dim_Product p ON f.Product_Key = p.Product_Key
GROUP BY f.Ship_Mode, p.Product_Container
ORDER BY Return_Rate DESC;

-- 3. Regional Shipping Performance and Return Correlation
SELECT 
    m.Region_Group,
    f.Ship_Mode,
    COUNT(f.Sales_ID) AS Total_Orders,
    COUNT(f.Return_Key) AS Returns_Count,
    ROUND((CAST(COUNT(f.Return_Key) AS FLOAT) / COUNT(f.Sales_ID)) * 100, 2) AS Return_Rate
FROM Fact_Sales f
JOIN Dim_Manager m ON f.Manager_Key = m.Manager_Key
GROUP BY m.Region_Group, f.Ship_Mode
ORDER BY Return_Rate DESC;
