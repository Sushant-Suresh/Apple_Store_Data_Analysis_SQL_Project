# Apple Store Data Analysis SQL Project

![1234](https://github.com/user-attachments/assets/e46cc8ec-7eb5-407c-9d29-22a6420de365)

## Project Overview

**Project Title**: Apple Store Data Analysis

**Database**: `apple_project`

This project is designed to demonstrate my SQL skills and techniques which I used to explore and analyze sales of different Apple stores. The project involves setting up a database and answering specific business questions through SQL queries.

## Objectives

1. **Set up a database**: Create and populate a database using the provided .csv files.
2. **Business Analysis**: Use SQL to answer specific business questions and derive insights from the data.

## Project Structure

### 1. Database and Schema Setup 

- **Database Creation**: The project starts by creating a database named `apple_project`.
- **Table Creation**: The following tables are created - `store`, `products`, `sales`.
```sql
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
```
**ERD For Database:**

![Apple_ERD](https://github.com/user-attachments/assets/172ac137-a8e4-4401-8157-765edd19d02b)

### 2. Data Imported Into Tables From the .csv Files
```sql
-- `products` Table Structure & Data
SELECT * FROM products;
```
**Output:**

![Products_Table](https://github.com/user-attachments/assets/54fe00e4-c807-4662-a803-866b47d43c26)
```sql
-- `store` Table Structure & Data
SELECT * FROM store;
```
**Output:**

![Store_Table](https://github.com/user-attachments/assets/8ef764de-2238-4191-987b-d1165901ac7e)
```sql
-- `sales` Table Structure & Data
SELECT * FROM sales;
```
**Output:**

![Sales_Table](https://github.com/user-attachments/assets/3df0d636-1e0b-4af1-90f2-315d9d539a1f)
### 3. Data Analysis & Findings

The following SQL queries were used to answer specific business questions:
1. **Add 2 Columns in the `sales` Table Which Show the Day of Sale & Sale Price Respectively.**
```sql
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
```
**Output:**

![Q1](https://github.com/user-attachments/assets/8c6946bf-8d08-4d13-9e6f-e2b7bff8ca9a)

2. **Find the Total Sale in India for the Last 5 Years.**
```sql
SELECT EXTRACT(YEAR FROM sa.saledate) AS year_,
       SUM(sale_price) AS india_sale
FROM sales AS sa
JOIN store AS st
ON sa.store_id = st.store_id
WHERE st.country = 'India'
AND sa.saledate >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY year_;
```
**Output:**

![Q2](https://github.com/user-attachments/assets/eccbba30-1fae-47a0-81a9-f407e4d0fbd8)

3. **Find Revenue, Total Orders & Quantity Ordered for Each Country in the Last Quarter of 2017.**
```sql
SELECT SUM(sa.sale_price) AS revenue, 
       SUM(sa.quantity) AS quantity_, 
	   COUNT(sa.sale_id) AS orders_placed,
	   st.country
FROM sales AS sa
JOIN store AS st
ON sa.store_id = st.store_id
WHERE sa.saledate BETWEEN '2017-10-01' AND '2017-12-31'
GROUP BY st.country;
```
**Output:**

![Q3](https://github.com/user-attachments/assets/369d4af8-4d62-4a89-9950-b6cae17a56b6)

4. **Find Top-5 Products With Highest Profit.**
```sql
SELECT product_name,
       ROUND(SUM(s.sale_price - (p.cogs * s.quantity))::numeric,1) AS profit
FROM products AS p
JOIN sales AS s
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY profit DESC
LIMIT 5;
```
**Output:**

![Q4](https://github.com/user-attachments/assets/799d9d33-23bc-421e-9361-45f0418e2798)

5. **How many units of each product have been sold?**
```sql
SELECT p.product_name,
       SUM(s.quantity) AS units_sold
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY p.product_name;
```
**Output:**

![Q5](https://github.com/user-attachments/assets/1c8f71d1-c9e6-4c62-838c-a7247b3ed7c5)

6. **Find Top-5 Best Selling Products.**
```sql
SELECT p.product_name,
       SUM(s.quantity) AS units_sold
FROM products AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC
LIMIT 5;
```
**Output:**

![Q6](https://github.com/user-attachments/assets/b0cc5573-a4eb-4668-ab2a-5e546b783a60)

7. **Distribute products across different pricing categories - Budget(<500), Mid-Range(500-1000) & Premium(>1000).**
```sql
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
```
**Output:**

![Q7](https://github.com/user-attachments/assets/4e5f332b-ecec-431b-85e1-aa8424cb5b51)

**Creating a CTAS for saving time while querying:**
```sql
CREATE TABLE orders_summary AS
SELECT p.product_id, p.product_name, p.category, p.price, p.cogs,
       st.store_id, st.store_name, st.country,
       sa.sale_id, sa.saledate, sa.sale_price, sa.quantity
FROM products AS p
JOIN sales AS sa
ON p.product_id = sa.product_id
JOIN store AS st
ON sa.store_id = st.store_id;

SELECT * FROM orders_summary;
```
**Output:**

![CTA](https://github.com/user-attachments/assets/401a55a5-6cbe-4b3c-9221-0396e728635e)

8. **Rank stores based on their performance (total orders processed).**
```sql
SELECT store_name,
       COUNT(*) AS total_orders,
       DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM orders_summary
GROUP BY store_name; 
```
**Output:**

![Q8](https://github.com/user-attachments/assets/78e010bf-5789-4418-a89f-99dbda9d7582)

9. **Evaluate the sales performance of each store (if sale > avg. sales categorize as 'High' else 'Low').**
```sql
SELECT store_name, 
       CASE 
           WHEN SUM(sale_price) > (SELECT AVG(total_sales) 
                                   FROM (SELECT SUM(sale_price) AS total_sales 
                                         FROM orders_summary 
                                         GROUP BY store_name) AS avg_sales) THEN 'High'
	   ELSE 'Low'
       END AS sales_performance
FROM orders_summary
GROUP BY store_name;
```
**Output:**

![Q9](https://github.com/user-attachments/assets/77f881f5-f9c3-443e-b8f1-1378075590e2)

10. **Categorize sales based on month of sale date ('Winter'/ 'Summer').**
```sql
SELECT COUNT(sale_id) AS products_sold,
       CASE 
           WHEN EXTRACT(MONTH FROM saledate) IN (11, 12, 1, 2) THEN 'Winter'
           WHEN EXTRACT(MONTH FROM saledate) IN (3, 4, 5, 6, 7, 8, 9, 10) THEN 'Summer'
       END AS season
FROM sales
GROUP BY season;
```
**Output:**

![Q10](https://github.com/user-attachments/assets/72223230-3490-47fb-8d02-ff597f867041)

11. **Identify top 5 products with decreasing revenue(%) compared to last year.**
```sql
WITH revenue_data AS (SELECT product_name, 
                             SUM(CASE WHEN EXTRACT(YEAR FROM saledate) = 2021 THEN sale_price ELSE 0 END) AS revenue_2021,
                             SUM(CASE WHEN EXTRACT(YEAR FROM saledate) = 2020 THEN sale_price ELSE 0 END) AS revenue_2020
                      FROM orders_summary
                      GROUP BY product_name)
SELECT product_name, 
       revenue_2021, 
       revenue_2020,
       ROUND((revenue_2021 - revenue_2020) / NULLIF(revenue_2020, 0) * 100::numeric, 2) AS revenue_dip_percentage
FROM revenue_data
WHERE revenue_2021 < revenue_2020
ORDER BY revenue_dip_percentage ASC
LIMIT 5;
```
**Output:**

![Q11](https://github.com/user-attachments/assets/ece6b55f-a41a-4403-b900-b51e652f5b2a)

12. **Find Y-O-Y growth for each store based on total profit.**
```sql
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
```
**Output:**

![Q12](https://github.com/user-attachments/assets/3e665b2a-37b5-4989-9c49-2541a3d707a1)

13. **Find each store's best selling month of 2020 and the sale made in that month.**
```sql
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
```
**Output:**

![Q13](https://github.com/user-attachments/assets/ed22de08-2372-46e5-a857-8ad6cbde3a08)

14. **Find the top 3 products with the highest total revenue for each store in 2020.**
```sql
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
```
**Output:**

![Q14](https://github.com/user-attachments/assets/f998f5f9-8dad-44d5-ba7e-c151918a327a)

15. **Find the avg. sale price of products sold by each store in 2020 & rank them based on their avg. sale price.**
```sql
WITH StoreAveragePrice AS (SELECT store_name,
                                  AVG(sale_price) AS avg_sale_price,
                                  ROW_NUMBER() OVER (ORDER BY AVG(sale_price) DESC) AS rank
                           FROM orders_summary
                           WHERE EXTRACT(YEAR FROM saledate) = 2020  
                           GROUP BY store_name)
SELECT store_name, avg_sale_price, rank
FROM StoreAveragePrice
ORDER BY rank;
```
**Output:**

![Q15](https://github.com/user-attachments/assets/97f12f4a-2982-4d70-a327-cdf9fe4637de)

## Conclusion

This project covers the following tasks: database setup, data importing and data analysis using business-driven SQL queries. The findings from this project can help drive business decisions by understanding key business metrics like revenue, profit, sales performance, and growth trends, covering various aspects of the data.
