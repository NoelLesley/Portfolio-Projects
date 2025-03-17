-- Creating table 
CREATE TABLE online_retail (
    InvoiceNo VARCHAR(20),       -- unique code assigned to each transaction. Code that starts with letter 'c',indicates a cancellation.
    StockCode VARCHAR(20),       -- Unique code assigned to product
    Description TEXT,            -- product name
    Quantity INT,                -- the quantities of each product  per transaction	
    InvoiceDate DATE,            -- the day and time when each transaction was generated
    UnitPrice DECIMAL(10,3),     -- product price per unit in sterling
    CustomerID INT,              -- a 5-digit integral number uniquely assigned to each custome
    Country VARCHAR(50)          -- Country were customer resides
);

SELECT * 
FROM online_retail;

-- Loading data into table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Online Retail.csv'
INTO TABLE online_retail
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS -- Skip header
(@InvoiceNo, @StockCode, @Description, @Quantity, @InvoiceDate, @UnitPrice, @CustomerID, @Country)
SET
    InvoiceNo = @InvoiceNo,
    StockCode = @StockCode,
    Description = @Description,
    Quantity = IF(@Quantity='',NULL,@Quantity),
    InvoiceDate = IF(@InvoiceDate = '', NULL, STR_TO_DATE(@InvoiceDate, '%d-%m-%Y')),
    UnitPrice = IF(@UnitPrice = '', NULL, @UnitPrice),
	CustomerID = IF(@CustomerID = '', NULL, @CustomerID),
    Country = @Country;



SELECT * 
FROM online_retail;

-- Data cleaning 
-- Removing null values 
DELETE
FROM online_retail
WHERE InvoiceNo IS NULL
OR StockCode IS NULL
OR Description IS NULL
OR Quantity IS NULL
OR InvoiceDate IS NULL
OR UnitPrice IS NULL
OR CustomerID IS NULL
OR Country IS NULL;

-- Removing duplicates
WITH duplicates as
(
SELECT * , 
ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country) AS no_of_instances
FROM online_retail
)
DELETE
FROM online_retail
WHERE (InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country) IN
(
    SELECT InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
    FROM duplicates
    WHERE no_of_instances > 1
);

-- Standardizing data
-- Removing '.' and ',' from description
UPDATE online_retail
SET Description = REPLACE(REPLACE(Description, '.',''),',','');

-- Removing records with invalide description (eg - '??/' , 'missing?')
DELETE
FROM online_retail
WHERE Description LIKE '%?%';

UPDATE online_retail
SET Description = LOWER(Description);

-- Descriptive Analysis Based of date
CREATE TEMPORARY TABLE sales_BY_date
SELECT YEAR(InvoiceDate) as Year ,MONTH(InvoiceDate) AS Month,DATE(InvoiceDate) AS Date,
MONTHNAME(InvoiceDate) AS Month_Name,DAYNAME(InvoiceDate) AS Weekday,Description,Quantity,UnitPrice
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%';

-- Net Sales per month
SELECT Year,Month_Name,SUM(Quantity * UnitPrice) AS Net_sales_per_month,AVG(Quantity * UnitPrice) AS average_sales,
RANK()OVER(ORDER BY SUM(Quantity * UnitPrice) DESC) AS sales_ranking
FROM sales_BY_date
GROUP BY Year,Month,Month_name
ORDER BY Year,Month;

-- Net Sales per week
SELECT Weekday,SUM(Quantity * UnitPrice) AS Net_sales_per_week,AVG(Quantity * UnitPrice) AS average_sales,
RANK()OVER(ORDER BY SUM(Quantity * UnitPrice) DESC) AS sales_ranking
FROM sales_BY_date
GROUP BY Weekday
ORDER BY FIELD(Weekday,'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday','Saturday');

-- Insights Summary
-- Net sales peaked during the Q4 , during September to December
-- Most sales were done during the midweek , tuesday to thursday 
-- Marketing campaigns and promotions can be focused around this period of time


-- Product based analysis
-- Helps in managing stock levels and forecasting demand
-- Identifies top 20 products that were ordered in bulk
WITH product_popularity AS
(
SELECT StockCode, Description, SUM(Quantity) AS total_sold,
RANK() OVER (ORDER BY SUM(Quantity) DESC) AS most_sold
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
AND Quantity >= 100 
GROUP BY StockCode,Description
)
SELECT *
FROM product_popularity
WHERE most_sold <= 20;

-- Identifies top 20 products that were ordered 
WITH product_popularity AS
(
SELECT StockCode, Description, SUM(Quantity) AS total_sold,
RANK() OVER (ORDER BY SUM(Quantity) DESC) AS most_sold
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
AND Quantity <= 100 
GROUP BY StockCode,Description
)
SELECT *
FROM product_popularity
WHERE most_sold <= 20;

-- Product sales
-- Identifies the 20 products generating the most revenue.
-- Helps in pricing strategy and promotional planning.
WITH product_sales AS
(
SELECT StockCode,Description,SUM(Quantity*UnitPrice) AS net_sales,
RANK()OVER(ORDER BY SUM(Quantity*UnitPrice) DESC) AS most_profitable
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY StockCode,Description
)
SELECT *
FROM product_sales 
WHERE most_profitable <= 20;


-- Region based analysis
-- Countries ranked based on net sales
SELECT Country,SUM(Quantity*UnitPrice)  AS Net_sales,
RANK()OVER(ORDER BY SUM(Quantity*UnitPrice) DESC) as Country_ranking
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY Country;


-- Most popular products purchesed in different countries
WITH popular_product AS 
(
SELECT Country,Description,COUNT(Description) AS times_purchased,
RANK()OVER(PARTITION BY Country ORDER BY COUNT(Description) DESC) as rank_number
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY Country,Description
)
SELECT Country,Description,times_purchased
FROM popular_product
WHERE rank_number = 1
AND times_purchased > 20    
ORDER BY times_purchased DESC;

-- Countries with Highest Average Order Value 
SELECT Country, SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo) AS Avg_Order_Value
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY Country
ORDER BY Avg_Order_Value DESC;

-- Peak Sales Month per Country
SELECT Country, MONTHNAME(InvoiceDate) AS Month, SUM(Quantity * UnitPrice) AS Monthly_Sales
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY Country, Month
ORDER BY Country, Monthly_Sales DESC;

-- Loss due to cancellations 
-- Regions with most cacellations 
SELECT Country,ABS(SUM(Quantity * UnitPrice)) AS net_loss_per_region, COUNT(DISTINCT InvoiceNo) AS number_transactions_cancelled
FROM online_retail
WHERE InvoiceNo LIKE '%C%'
GROUP BY Country
ORDER BY ABS(SUM(Quantity * UnitPrice)) DESC;

-- Months with most cancellations
SELECT Year(InvoiceDate) AS Year,MONTHNAME(InvoiceDate) AS Month,ABS(SUM(Quantity * UnitPrice)) AS net_loss_per_month,
 COUNT(DISTINCT InvoiceNo) AS number_transactions_cancelled
FROM online_retail
WHERE InvoiceNo LIKE '%C%'
GROUP BY Year(InvoiceDate),MONTHNAME(InvoiceDate)
ORDER BY ABS(SUM(Quantity * UnitPrice)) DESC;


-- Products with most cancellations 
SELECT Description,ABS(SUM(Quantity * UnitPrice)) AS net_loss, COUNT(DISTINCT InvoiceNo) AS number_transactions_cancelled
FROM online_retail
WHERE InvoiceNo LIKE '%C%'
GROUP BY Description
HAVING net_loss > 6000
ORDER BY ABS(SUM(Quantity * UnitPrice)) DESC;

-- Customer Analysis
-- Customers with most purchases
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS num_purchases
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY CustomerID
HAVING Num_Purchases > 25
ORDER BY num_purchases DESC;

-- Customers with highest expenditures
SELECT CustomerID, SUM(Quantity*UnitPrice) AS total_spent
FROM online_retail
WHERE InvoiceNo NOT LIKE '%C%'
GROUP BY CustomerID
HAVING total_spent > 10000
ORDER BY total_spent DESC;

-- Customers with most cancellations
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS num_purchases_cancelled
FROM online_retail
WHERE InvoiceNo LIKE '%C%'
GROUP BY CustomerID
HAVING num_purchases_cancelled > 10
ORDER BY num_purchases_cancelled DESC;






