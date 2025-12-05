SELECT COUNT(*) AS total_customers 
FROM customers;

SELECT COUNT(*) AS total_products 
FROM products;

SELECT COUNT(*) AS total_sales 
FROM sales;

SELECT TOP 3 * 
FROM customers;
SELECT TOP 3 * 
FROM products;
SELECT TOP 3 * 
FROM sales;

--Total Revenue 
SELECT SUM(Purchase_Amount_USD) AS Total_Revenue
FROM customers;

-- Average Purchase Amount 
SELECT AVG(Purchase_Amount_USD) AS Avg_Purchase_Amount
FROM customers;

--Top 10 Customers by Spending
SELECT TOP 10
Customer_ID, [Location],Purchase_Amount_USD
FROM customers
ORDER BY Purchase_Amount_USD;

--Products by Categories
SELECT main_category,
COUNT(*) AS Product_Count
FROM products
GROUP BY main_category
ORDER BY Product_Count DESC;

--Male vs Female Customers
SELECT Gender,
COUNT(*) AS Customer_Count
FROM customers
GROUP BY Gender;

--Sales by Month
SELECT  
    YEAR([timestamp]) AS sales_year,
    DATENAME(MONTH, [timestamp]) AS sales_month,
    COUNT(*) AS purchase_count
FROM sales
GROUP BY 
    YEAR([timestamp]),
    DATENAME(MONTH, [timestamp]),
    MONTH([timestamp])
ORDER BY 
    sales_year,
    MONTH([timestamp]);

--Top 10 Revenue by Location
SELECT TOP 10 [Location],
SUM(Purchase_Amount_USD) AS Total_Revenue
FROM customers
GROUP BY [Location]
ORDER BY Total_Revenue DESC;

--Customers with Subscription
SELECT Subscription_Status,
COUNT(*) AS Total_Customers
FROM customers
GROUP BY Subscription_Status;

--Average Review Rating by Category
SELECT Category, ROUND(AVG(Review_Rating),2) AS Avg_Review_Rating
FROM customers
GROUP BY Category
ORDER BY Avg_Review_Rating;

--Products Purchased in Summer
SELECT Item_Purchased,
COUNT(*) AS Purchase_Count
FROM customers
WHERE Season = 'Summer'
GROUP BY item_purchased
ORDER BY purchase_count DESC;

--Products Sold
SELECT 
    [Item_Purchased] AS Product_Name,
    COUNT(*) AS Times_Sold
FROM customers
GROUP BY [Item_Purchased]
ORDER BY Times_Sold DESC;


--Customers Who Used Promo Codes
SELECT 
COUNT(Customer_ID) AS Promo_Purchases,
SUM(Purchase_Amount_USD) AS Total_Revenue
FROM customers
WHERE Promo_Code_Used = 'Yes';

--Payment Method Preference 
SELECT 
    Payment_method,
    COUNT(*) AS customer_count,
    ROUND(
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers)), 2) AS percentage_of_customers
FROM customers
GROUP BY Payment_method
ORDER BY percentage_of_customers DESC;

--Customer Segmentation (RFM - Monetary)
--Segment customers into High, Medium, Low value based on purchase amount
SELECT
    CASE 
        WHEN Purchase_Amount_USD >= 80 THEN 'High Value'
        WHEN Purchase_Amount_USD BETWEEN 50 AND 79 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_segment,
    COUNT(*) AS Customer_count
FROM customers
GROUP BY 
    CASE 
        WHEN Purchase_Amount_USD >= 80 THEN 'High Value'
        WHEN Purchase_Amount_USD BETWEEN 50 AND 79 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY customer_count DESC;

--Products Never Sold
SELECT 
    p.product_id,
    p.product_name
FROM products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM sales s
    WHERE s.product_id = p.product_id
);

--Top 5 Products by Revenue
SELECT 
    Item_Purchased AS Product_Name,
    COUNT(*) AS Times_Sold,
    SUM(Purchase_Amount_USD) AS Total_Revenue
FROM customers
GROUP BY Item_Purchased
ORDER BY Total_Revenue DESC;


--Monthly Sales Trend
SELECT
    YEAR(s.[timestamp]) AS Sales_year,
    DATENAME(MONTH, s.[timestamp]) AS Sales_month,
    COUNT(*) AS Total_sales,
    ROUND(SUM(p.selling_price),2) AS Total_revenue
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    YEAR(s.[timestamp]),
    DATENAME(MONTH, s.[timestamp])
ORDER BY
    YEAR(s.[timestamp]),
    DATENAME(MONTH, s.[timestamp]);

--Customers with Above-Average Spending
SELECT Customer_ID, [Location], Purchase_Amount_USD
FROM customers
WHERE Purchase_Amount_USD > ( 
      SELECT AVG(Purchase_Amount_USD)
      FROM customers
)
ORDER BY Purchase_Amount_USD DESC;

--Customer Lifetime Analysis with Ranking
--Rank customers by their purchase amount and show their rank, along with previous purchases count.
SELECT Customer_ID, Age, Gender, [Location], Purchase_Amount_USD, Previous_Purchases,
RANK()OVER(ORDER BY Purchase_Amount_USD DESC) AS Customer_Rank
FROM customers
ORDER BY Customer_Rank;

--COHORT ANALYSIS(how many customers made their first purchase in each month)
WITH FirstPurchase AS (
    SELECT 
        [user_id],
        MIN([timestamp]) AS first_purchase_date
    FROM sales
    GROUP BY [user_id]
)
SELECT
    YEAR(first_purchase_date) AS Purchase_Year,
    DATENAME(MONTH, first_purchase_date) AS Purchase_Month,
    COUNT(*) AS Customers_First_Purchase
FROM FirstPurchase
GROUP BY 
    YEAR(first_purchase_date),
    DATENAME(MONTH, first_purchase_date),
    MONTH(first_purchase_date)
ORDER BY 
    YEAR(first_purchase_date),
    MONTH(first_purchase_date);

--Cummulative Revenue Overtime(Running Total) 
SELECT
    YEAR([timestamp]) AS Sales_Year,
    DATENAME(MONTH, [timestamp]) AS Sales_Month,
    ROUND(SUM(selling_price), 2) AS Monthly_Revenue,
    ROUND(
            SUM(SUM(selling_price)) OVER (
        ORDER BY YEAR([timestamp]), MONTH([timestamp])
    ), 2 
 )AS Cumulative_Revenue
FROM sales s
INNER JOIN products p
    ON s.product_id = p.product_id
GROUP BY
    YEAR([timestamp]),
    DATENAME(MONTH, [timestamp]),
    MONTH([timestamp])
ORDER BY
    sales_year,
    MONTH([timestamp]);

    -- Customer dataset for ML
SELECT 
    c.Customer_ID,
    c.Age,
    c.Gender,
    c.Item_Purchased,
    c.Purchase_Amount_USD,
    c.Location,
    c.Category,
    c.Season,
    c.Review_Rating,
    c.Previous_Purchases,
    c.Subscription_Status,
    c.Discount_Applied,
    c.Promo_Code_Used,
    c.Payment_Method,
    c.Frequency_of_Purchases,
    -- Calculated features
    CASE 
        WHEN c.Purchase_Amount_USD >= 80 THEN 'High Value'
        WHEN c.Purchase_Amount_USD >= 50 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    CASE 
        WHEN c.previous_purchases >= 30 THEN 'Loyal'
        WHEN c.previous_purchases >= 10 THEN 'Regular'
        ELSE 'New'
    END AS customer_type
FROM customers c;


--Product Performance Dataset
SELECT 
    Item_Purchased AS Product_Name,
    Category AS Main_Category,
    COUNT(*) AS Total_Units_Sold,
    SUM(Purchase_Amount_USD) AS Total_Revenue,
    AVG(Purchase_Amount_USD) AS Avg_Price
FROM customers
GROUP BY Item_Purchased, Category
ORDER BY Total_Units_Sold DESC;

