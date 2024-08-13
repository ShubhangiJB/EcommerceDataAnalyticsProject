--Clean Up Query
UPDATE 
  `sample_ecommerce_data_50k.sample`
SET 
  OrderDate_Cleaned = 
CASE
   WHEN REGEXP_CONTAINS(OrderDate, r'[0-9]{1,2}\-[0-9]{1,2}\-[0-9]{4}') THEN PARSE_DATE('%d-%m-%Y',OrderDate) 
   WHEN REGEXP_CONTAINS(OrderDate, r'[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}') THEN PARSE_DATE('%m/%d/%Y',REGEXP_EXTRACT(OrderDate, r'[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}'))
   ELSE NULL
END;


-- 1. Calculate the total sales for each month over the past two years. Identify the month with the highest sales. What is the average order value (AOV) per month?

SELECT 
  EXTRACT(MONTH FROM OrderDate_Cleaned) as Mon, 
  ROUND(SUM(Quantity*UnitPrice),2) as Total_Sales, 
  SUM(Quantity) as Total_Units_Sold, 
  ROUND(SUM(Quantity*UnitPrice)/SUM(Quantity), 2) as Avg_Order_Value
FROM 
  sample_ecommerce_data_50k.sample 
GROUP BY 
  Mon
ORDER BY 
  Total_Sales DESC;


--2.	Product Performance:Which product category has the highest sales volume? Provide a breakdown of sales by product category.

SELECT 
  ProductCategory, 
  ROUND(SUM(Quantity*UnitPrice),2) as Total_Sales, 
  SUM(Quantity) as Total_Units_Sold, 
  ROUND(SUM(Quantity*UnitPrice)/SUM(Quantity), 2) as Avg_Order_Value
FROM 
  sample_ecommerce_data_50k.sample 
GROUP BY 
  ProductCategory
ORDER BY 
  Total_Sales DESC;


--3.	Determine the top 5 customer segments by total sales. What percentage of total sales does each segment contribute?

SELECT 
  CustomerSegment, 
  TotalSales, 
  ROUND((TotalSales / GrandTotalSales) * 100,2) AS SalesPercentage
FROM (
  SELECT 
    CustomerSegment, 
    ROUND(SUM(Quantity * UnitPrice)) AS TotalSales, 
    SUM(SUM(Quantity * UnitPrice)) OVER () AS GrandTotalSales
  FROM 
    `sample_ecommerce_data_50k.sample`
  GROUP BY 
    CustomerSegment
)
ORDER BY 
  TotalSales DESC
LIMIT 5;


--4. Calculate the average number of orders per customer. Identify customers with the highest repeat order rate.

SELECT 
  ROUND(SUM(Quantity)/COUNT(DISTINCT(CustomerID))) AS AvgOrdersPerCust
FROM 
  `sample_ecommerce_data_50k.sample`;

SELECT 
  DISTINCT(CustomerID) as Customer_ID, 
  COUNT(OrderID) as NumOfOrders
FROM 
  `sample_ecommerce_data_50k.sample`
GROUP BY 
  Customer_ID
HAVING 
  NumOfOrders = 10
ORDER BY 
  NumOfOrders DESC;


--5.	Analyze sales distribution by region. Which region has the highest sales? Provide insights into regional performance.

SELECT 
  Region, 
  ROUND(SUM(Quantity * UnitPrice)) AS TotalSales, 
  ROUND(SUM((Quantity * UnitPrice)/Quantity)) as AvgSales
FROM 
  `sample_ecommerce_data_50k.sample`
GROUP BY 
  Region
ORDER BY 
  TotalSales DESC;


  --6. Compare the average shipping cost across different regions. Identify any regions with significantly higher shipping costs.

SELECT 
  DISTINCT(Region), 
  ROUND((SUM(ShippingCost)/COUNT(*)),2) as AvgShipping
FROM 
  `sample_ecommerce_data_50k.sample`
GROUP BY 
  Region
ORDER BY 
  AvgShipping DESC;

  
--7.	Calculate the average time taken to ship orders (difference between order date and ship date). Identify any trends or patterns.

SELECT 
  MAX(DATE_DIFF(ShipDate_Cleaned, OrderDate_Cleaned, DAY)) as MaxDiffBtwOrderAndShippingDates, 
  MIN(DATE_DIFF(ShipDate_Cleaned, OrderDate_Cleaned, DAY)) as MinDiffBtwOrderAndShippingDates, 
  AVG(DATE_DIFF(ShipDate_Cleaned, OrderDate_Cleaned, DAY)) as AvgDiffBtwOrderAndShippingDates
FROM 
  `sample_ecommerce_data_50k.sample`;

  
--8. Determine the percentage of orders with shipping costs greater than $30. Analyze the potential reasons for high shipping costs.

SELECT 
  COUNTIF(ShippingCost > 30) / COUNT(*) * 100 AS PercentageOver30
FROM 
  `sample_ecommerce_data_50k.sample`;


--9.	Identify customers who have placed more than one order. What percentage of total customers are repeat customers?

SELECT 
  (COUNT(Customer_ID)*100/totalCustomers) AS percentRepeatedCustomers
FROM (
SELECT 
  DISTINCT(CustomerID) as Customer_ID, 
  COUNT(OrderID) as NumOfOrders, 
  COUNT(CustomerID) OVER() as totalCustomers
FROM 
  `sample_ecommerce_data_50k.sample`
GROUP BY 
  Customer_ID
)
WHERE 
  NumOfOrders > 1
GROUP BY 
  totalCustomers;

  
--10. Calculate the average time between repeat orders for these customers.

WITH OrderedCustomerData AS (
    SELECT
        CustomerID,
        OrderDate_Cleaned,
        LAG(OrderDate_Cleaned) OVER (PARTITION BY CustomerID ORDER BY OrderDate_Cleaned) AS PreviousOrderDate
    FROM
        `project_id.dataset_id.table_name`
),
OrderDifferences AS (
    SELECT
        CustomerID,
        DATE_DIFF(OrderDate_Cleaned, PreviousOrderDate, DAY) AS DaysBetweenOrders
    FROM
        OrderedCustomerData
    WHERE
        PreviousOrderDate IS NOT NULL  -- Exclude the first order since it has no previous order to compare
)
SELECT
    CustomerID,
    AVG(DaysBetweenOrders) AS AvgDaysBetweenOrders
FROM
    OrderDifferences
GROUP BY
    CustomerID
ORDER BY
    AvgDaysBetweenOrders;

