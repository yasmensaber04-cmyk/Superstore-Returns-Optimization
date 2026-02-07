-- 1. General Product Return Rate (All Returns)

SELECT 

    p.Product_Name,

    p.Category,

    COUNT(f.Sales_ID) AS Total_Sold,

    COUNT(f.Return_Key) AS Total_Returned,

    (CAST(COUNT(f.Return_Key) AS FLOAT) / COUNT(f.Sales_ID)) * 100 AS Return_Rate

FROM Fact_Sales f

JOIN Dim_Product p ON f.Product_Key = p.Product_Key

GROUP BY p.Product_Name, p.Category

HAVING COUNT(f.Return_Key) > 0

ORDER BY Return_Rate DESC;



-- 2. Top 10 High-Volume Products with Highest Return Rates (Min 5 Sales)

SELECT TOP 10

    p.Product_Name,

    p.Category,

    COUNT(f.Sales_ID) AS Total_Sold,

    COUNT(f.Return_Key) AS Total_Returned,

    (CAST(COUNT(f.Return_Key) AS FLOAT) / COUNT(f.Sales_ID)) * 100 AS Return_Rate

FROM Fact_Sales f

JOIN Dim_Product p ON f.Product_Key = p.Product_Key

GROUP BY p.Product_Name, p.Category

HAVING COUNT(f.Sales_ID) >= 5 

ORDER BY Return_Rate DESC;



-- 3. Product Classification by Market Demand

SELECT 

    CASE 

        WHEN Sales_Count = 1 THEN 'Single-Order Products (New/Low Demand)'

        WHEN Sales_Count BETWEEN 2 AND 5 THEN 'Low Demand Products'

        ELSE 'High Demand / Popular'

    END AS Product_Status,

    COUNT(Product_Name) AS Number_of_Products

FROM (

    SELECT 

        p.Product_Name, 

        COUNT(f.Sales_ID) AS Sales_Count

    FROM Fact_Sales f

    JOIN Dim_Product p ON f.Product_Key = p.Product_Key

    GROUP BY p.Product_Name

) AS Product_Stats

GROUP BY 

    CASE 

        WHEN Sales_Count = 1 THEN 'Single-Order Products (New/Low Demand)'

        WHEN Sales_Count BETWEEN 2 AND 5 THEN 'Low Demand Products'

        ELSE 'High Demand / Popular'

    END;



-- 4. Orphaned Products Aging Analysis (Single Order Lifetime)

DECLARE @LastDateInDB DATE = (SELECT MAX(Order_Date) FROM Fact_Sales);



SELECT 

    p.Product_Name,

    p.Category,

    MIN(f.Order_Date) AS Date_Ordered,

    DATEDIFF(DAY, MIN(f.Order_Date), @LastDateInDB) AS Days_Since_Last_Order,

    CASE 

        WHEN DATEDIFF(DAY, MIN(f.Order_Date), @LastDateInDB) < 180 THEN 'New - Under Testing'

        WHEN DATEDIFF(DAY, MIN(f.Order_Date), @LastDateInDB) BETWEEN 180 AND 730 THEN 'Stagnant - Needs Action'

        ELSE 'Dead Stock - Remove from Catalog'

    END AS Product_Lifecycle_Status

FROM Fact_Sales f

JOIN Dim_Product p ON f.Product_Key = p.Product_Key

GROUP BY p.Product_Name, p.Category

HAVING COUNT(f.Sales_ID) = 1

ORDER BY Date_Ordered ASC;



-- 5. Financial Sunk Cost Analysis for Dead Stock

SELECT 

    COUNT(p.Product_Name) AS Total_Dead_Products,

    SUM(f.Sales) AS Total_Sales_Value,

    SUM(f.Profit) AS Total_Net_Profit_Loss,

    SUM(f.Shipping_Cost) AS Total_Shipping_Sunk_Cost,

    CASE 

        WHEN SUM(f.Profit) < 0 THEN 'Direct Financial Loss'

        ELSE 'Opportunity Cost Loss'

    END AS Loss_Type

FROM Fact_Sales f

JOIN Dim_Product p ON f.Product_Key = p.Product_Key

WHERE p.Product_Name IN (

    SELECT p2.Product_Name

    FROM Fact_Sales f2

    JOIN Dim_Product p2 ON f2.Product_Key = p2.Product_Key

    GROUP BY p2.Product_Name

    HAVING COUNT(f2.Sales_ID) = 1

);
