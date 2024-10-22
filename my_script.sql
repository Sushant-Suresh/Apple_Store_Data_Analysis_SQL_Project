-- Creating Database
CREATE DATABASE apple_project;

-- Creating `store` Table
DROP TABLE IF EXISTS store;
CREATE TABLE store (store_id INT PRIMARY KEY, store_name VARCHAR(35) NOT NULL, 
                    country VARCHAR(25) NOT NULL, city VARCHAR(35));

-- Creating `products` Table
DROP TABLE IF EXISTS products;
CREATE TABLE products (product_id INT PRIMARY KEY, product_name VARCHAR(35), 
                       category VARCHAR(35), price FLOAT, launched_price FLOAT, cogs FLOAT);


-- Creating `sales` Table
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (sale_id INT PRIMARY KEY, store_id INT, product_id INT, saledate DATE, quantity INT,
                    CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES store(store_id),
                    CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id));

/*
Hierarchy Followed for Importing Data Into Tables:
products > store > sales  
*/

-- Imported Data From .csv Files

-- Querying the Table to See the Table Structure & Data
SELECT * FROM products;
SELECT * FROM store;
SELECT * FROM sales;

-- Q1. Add 2 Columns in the `sales` Table Which Show the Day of Sale & Sale Price Respectively.
ALTER TABLE sales
ADD COLUMN sale_day VARCHAR(10);
UPDATE sales
SET sale_day = TRIM(TO_CHAR(saledate,'day'));

ALTER TABLE sales
ADD COLUMN sale_price FLOAT;
UPDATE sales AS s
SET sale_price = s.quantity * p.price
FROM products AS p
WHERE s.product_id = p.product_id;

SELECT saledate, sale_day, sale_price  -- Querying the new columns
FROM sales;

-- Q2. Find the Total Sale in India for the Last 5 Years.
SELECT EXTRACT(YEAR FROM sa.saledate) AS year_,
       SUM(sale_price) AS india_sale
FROM sales AS sa
JOIN store AS st
ON sa.store_id = st.store_id
WHERE st.country = 'India'
AND sa.saledate >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY year_;

-- Q3. Find Revenue, Total Orders & Quantity Ordered for Each Country in the Last Quarter of 2017.
SELECT SUM(sa.sale_price) AS revenue, 
       SUM(sa.quantity) AS quantity_, 
	   COUNT(sa.sale_id) AS orders_placed,
	   st.country
FROM sales AS sa
JOIN store AS st
ON sa.store_id = st.store_id
WHERE sa.saledate BETWEEN '2017-10-01' AND '2017-12-31'
GROUP BY st.country;

-- Q4. Find Top-5 Products With Highest Profit.
SELECT product_name,
       ROUND(SUM(s.sale_price - (p.cogs * s.quantity))::numeric,1) AS profit
FROM products AS p
JOIN sales AS s
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY profit DESC
LIMIT 5;

-- Q5. How many units of each product have been sold?
SELECT p.product_name,
       SUM(s.quantity) AS units_sold
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY p.product_name;

-- Q6. Find Top-5 Best Selling Products.
SELECT p.product_name,
       SUM(s.quantity) AS units_sold
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 5;

-- Q7. Distribute products across different pricing categories - Budget(<500), Mid-Range(500-1000) & Premium(>1000).
WITH category_CTE AS (SELECT product_name,
                               CASE
	                               WHEN price < 500 THEN 'BUDGET'
		                           WHEN price BETWEEN 500 AND 1000 THEN 'MID-RANGE'
		                           ELSE 'PREMIUM'
	                           END AS product_category
                      FROM products)	   
SELECT product_category,
       COUNT(product_name)
FROM category_CTE
GROUP BY product_category;

-- Creating a CTAS for saving time while querying: 
CREATE TABLE orders_summary AS
SELECT p.product_id, p.product_name, p.category, p.price, p.cogs,
       st.store_id, st.store_name, st.country,
	   sa.sale_id, sa.saledate, sa.sale_price, sa.quantity
FROM products AS p
JOIN sales AS sa
ON p.product_id = sa.product_id
JOIN store AS st
ON sa.store_id = st.store_id;

-- Q8. Rank stores based on their performance (total orders processed).
SELECT store_name,
       COUNT(*) AS total_orders,
	   DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM orders_summary
GROUP BY store_name; 

-- Q9. Evaluate the sales performance of each store (if sale > avg. sales categorize as 'High' else 'Low').
SELECT store_name, 
       CASE 
	       WHEN SUM(sale_price) > (SELECT AVG(total_sales) 
                                   FROM (SELECT SUM(sale_price) AS total_sales 
                                         FROM orders_summary 
                                         GROUP BY store_name) AS avg_sales) THEN 'High'
	   ELSE 'Low' END
	   AS sales_performance
FROM orders_summary
GROUP BY store_name;

-- Q10. Categorize sales based on month of sale date ('Winter'/ 'Summer').
SELECT COUNT(sale_id) AS products_sold,
       CASE 
           WHEN EXTRACT(MONTH FROM saledate) IN (11, 12, 1, 2) THEN 'Winter'
           WHEN EXTRACT(MONTH FROM saledate) IN (3, 4, 5, 6, 7, 8, 9, 10) THEN 'Summer'
       END AS season
FROM sales
GROUP BY season;

-- Q11. Identify top 5 products with decreasing revenue(%) compared to last year.
WITH revenue_data AS (SELECT product_name, 
                             SUM(CASE WHEN EXTRACT(YEAR FROM saledate) = 2021 THEN sale_price ELSE 0 END) AS revenue_2021,
                             SUM(CASE WHEN EXTRACT(YEAR FROM saledate) = 2020 THEN sale_price ELSE 0 END) AS revenue_2020
                      FROM orders_summary
                      GROUP BY product_name)
SELECT product_name, 
       revenue_2021, 
       revenue_2020,
       ROUND((revenue_2021 - revenue_2020) / NULLIF(revenue_2020, 0) * 100::numeric, 2)
FROM revenue_data
WHERE revenue_2021 < revenue_2020
ORDER BY revenue_dip_percentage ASC
LIMIT 5;

-- Q12. Find Y-O-Y growth for each store based on total profit.
WITH yearly_profit AS (SELECT EXTRACT(YEAR FROM saledate) AS sale_year,
                              store_name,
                              SUM(quantity * (sale_price - cogs)) AS total_profit
                       FROM orders_summary
                       GROUP BY EXTRACT(YEAR FROM saledate), store_name)

SELECT  store_name,
        -- Growth for 2017-2018
        ((MAX(CASE WHEN sale_year = 2018 THEN total_profit END) - MAX(CASE WHEN sale_year = 2017 THEN total_profit END)) / 
          NULLIF(MAX(CASE WHEN sale_year = 2017 THEN total_profit END), 0)) * 100 AS "% Growth 17-18",
	  
        -- Growth for 2018-2019
        ((MAX(CASE WHEN sale_year = 2019 THEN total_profit END) - MAX(CASE WHEN sale_year = 2018 THEN total_profit END)) / 
          NULLIF(MAX(CASE WHEN sale_year = 2018 THEN total_profit END), 0)) * 100 AS "% Growth 18-19",
    
        -- Growth for 2019-2020
        ((MAX(CASE WHEN sale_year = 2020 THEN total_profit END) - MAX(CASE WHEN sale_year = 2019 THEN total_profit END)) / 
          NULLIF(MAX(CASE WHEN sale_year = 2019 THEN total_profit END), 0)) * 100 AS "% Growth 19-20",
    
        -- Growth for 2020-2021
        ((MAX(CASE WHEN sale_year = 2021 THEN total_profit END) - MAX(CASE WHEN sale_year = 2020 THEN total_profit END)) / 
          NULLIF(MAX(CASE WHEN sale_year = 2020 THEN total_profit END), 0)) * 100 AS "% Growth 20-21"
FROM yearly_profit
GROUP BY store_name;

-- Q13. Find each store's best selling month of 2020 and the sale made in that month.
WITH monthly_sales AS (SELECT store_name,
                              TO_CHAR(saledate, 'Month') AS best_selling_month,
                              SUM(quantity * sale_price) AS total_sales
                       FROM orders_summary
                       WHERE EXTRACT(YEAR FROM saledate) = 2020
                       GROUP BY store_name, EXTRACT(MONTH FROM saledate), TO_CHAR(saledate, 'Month'))

SELECT store_name, best_selling_month, total_sales
FROM monthly_sales
WHERE total_sales = (SELECT MAX(total_sales)
                     FROM monthly_sales AS ms
                     WHERE ms.store_name = monthly_sales.store_name);

-- Q14. Find the top 3 products with the highest total revenue for each store in 2020.
WITH ProductRevenue AS (SELECT store_name,
                               product_name,
                               SUM(sale_price * quantity) AS total_revenue,
                               ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY SUM(sale_price * quantity) DESC) AS rank
                        FROM orders_summary
                        WHERE EXTRACT(YEAR FROM saledate) = 2020 
                        GROUP BY store_name, product_name)
SELECT store_name, product_name, total_revenue
FROM ProductRevenue
WHERE rank <= 3  
ORDER BY store_name, total_revenue DESC;

-- Q15. Find the avg. sale price of products sold by each store in 2020 & rank them based on their avg. sale price.
WITH StoreAveragePrice AS (SELECT store_name,
                                  AVG(sale_price) AS avg_sale_price,
                                  ROW_NUMBER() OVER (ORDER BY AVG(sale_price) DESC) AS rank
                           FROM orders_summary
                           WHERE EXTRACT(YEAR FROM saledate) = 2020  
                           GROUP BY store_name)
SELECT store_name, avg_sale_price, rank
FROM StoreAveragePrice
ORDER BY rank;
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
