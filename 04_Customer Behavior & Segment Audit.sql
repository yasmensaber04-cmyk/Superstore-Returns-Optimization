-- 1. Return Distribution across Customer Segments
SELECT 
    f.Customer_Segment,
    COUNT(f.Return_Key) AS Returns_Count
FROM Fact_Sales f
WHERE f.Return_Key IS NOT NULL
GROUP BY f.Customer_Segment
ORDER BY Returns_Count DESC;

-- 2. Corporate Segment Sunk Shipping Costs Analysis
SELECT 
    f.Customer_Segment,
    COUNT(f.Return_Key) AS Total_Returns,
    SUM(f.Shipping_Cost) AS Sunk_Shipping_Costs,
    SUM(f.Sales) AS Lost_Sales_Value,
    AVG(f.Shipping_Cost) AS Avg_Shipping_Per_Return
FROM Fact_Sales f
WHERE f.Return_Key IS NOT NULL AND f.Customer_Segment = 'Corporate'
GROUP BY f.Customer_Segment;

-- 3. Detailed Corporate Returns by Region and Product
SELECT 
    f.Ship_Mode,
    m.Region_Group,
    p.Product_Name,
    COUNT(f.Return_Key) AS Total_Returns,
    SUM(f.Shipping_Cost) AS Waste_Shipping_Cost,
    SUM(f.Sales) AS Lost_Sales
FROM Fact_Sales f
JOIN Dim_Manager m ON f.Manager_Key = m.Manager_Key
JOIN Dim_Product p ON f.Product_Key = p.Product_Key
WHERE f.Customer_Segment = 'Corporate' AND f.Return_Key IS NOT NULL
GROUP BY f.Ship_Mode, m.Region_Group, p.Product_Name
ORDER BY Total_Returns DESC;

-- 4. Corporate Customer Return Rate & Waste Scorecard
SELECT 
    O.[Customer_Name], 
    COUNT(F.Sales_ID) AS Total_Orders,
    COUNT(F.Return_Key) AS Returned_Orders,
    ROUND((CAST(COUNT(F.Return_Key) AS FLOAT) / NULLIF(COUNT(F.Sales_ID), 0)) * 100, 2) AS Return_Rate_Percent,
    SUM(F.Shipping_Cost) AS Total_Shipping_Waste
FROM Fact_Sales AS F
JOIN Orders AS O ON F.Order_ID = O.Order_ID AND F.Sales = O.Sales 
WHERE F.Customer_Segment = 'Corporate'
GROUP BY O.[Customer_Name]
HAVING COUNT(F.Return_Key) > 0 
ORDER BY Return_Rate_Percent DESC;

-- 5. Customer Diagnostic: Intent Analysis (Serious vs. Non-Serious)
SELECT 
    O.[Customer_Name],
    COUNT(DISTINCT F.Product_Key) AS Different_Products_Ordered,
    COUNT(F.Return_Key) AS Total_Returns,
    AVG(F.Shipping_Cost) AS Avg_Shipping_Cost,
    CASE 
        WHEN COUNT(DISTINCT F.Product_Key) > 1 AND COUNT(F.Return_Key) > 1 THEN 'High Probability: Unserious Customer'
        ELSE 'Check Product Quality'
    END AS Diagnostic_Result
FROM Fact_Sales AS F
JOIN Orders AS O ON F.Order_ID = O.Order_ID
WHERE F.Customer_Segment = 'Corporate'
GROUP BY O.[Customer_Name]
HAVING COUNT(F.Return_Key) > 0
ORDER BY Total_Returns DESC;
