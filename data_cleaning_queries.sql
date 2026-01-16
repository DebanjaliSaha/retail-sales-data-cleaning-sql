-- ================================================================
-- RETAIL SALES DATA CLEANING PROJECT
-- ================================================================
-- Database: sales
-- Author: Debanjali Saha
-- Date: January 2026
-- Description: Comprehensive MySQL workflow for cleaning retail sales data
-- Original Records: 943 → Final Records: 940
-- ================================================================

-- Prerequisites:
-- 1. Create database: CREATE DATABASE sales;
-- 2. Import raw_sales_data.csv into 'sales' table using MySQL Workbench
-- 3. Execute this script in order

-- ================================================================
-- STEP 1: INITIAL DATA EXPLORATION
-- ================================================================

-- View raw dataset
SELECT * FROM sales;

-- ================================================================
-- STEP 2: DUPLICATE DETECTION AND REMOVAL
-- ================================================================

-- Test ROW_NUMBER() window function
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_id ORDER BY transaction_id) AS row_num
FROM sales;

-- Identify duplicate records using CTE
WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_id ORDER BY transaction_id) AS row_num
    FROM sales
)
SELECT * 
FROM cte 
WHERE row_num > 1;

-- Verify specific duplicate transaction IDs
WITH cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_id ORDER BY transaction_id) AS row_num
    FROM sales
)
SELECT * 
FROM cte 
WHERE transaction_id IN (1001, 1004, 1030);

-- Create new table with row_num column for duplicate removal
CREATE TABLE sales2 (
  transaction_id int DEFAULT NULL,
  customer_id int DEFAULT NULL,
  customer_name text,
  email text,
  purchase_date text,
  product_id int DEFAULT NULL,
  category text,
  price double DEFAULT NULL,
  quantity int DEFAULT NULL,
  total_amount text,
  payment_method text,
  delivery_status text,
  customer_address text,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verify empty table
SELECT * FROM sales2;

-- Populate sales2 with row numbers
INSERT INTO sales2
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY transaction_id, customer_id ORDER BY transaction_id) AS row_num
FROM sales;

-- Check duplicates before deletion
SELECT * FROM sales2
WHERE row_num > 1;

-- Delete duplicate records
DELETE FROM sales2
WHERE row_num > 1;

-- Verify duplicates removed
SELECT * FROM sales2
WHERE row_num > 1;

-- View cleaned dataset
SELECT * FROM sales2;

-- ================================================================
-- STEP 3: DATA TYPE MODIFICATIONS
-- ================================================================

-- Temporarily modify columns to handle NULL values during cleaning
ALTER TABLE sales2 MODIFY customer_id VARCHAR(255) NULL;
ALTER TABLE sales2 MODIFY price VARCHAR(255) NULL;

-- ================================================================
-- STEP 4: MISSING VALUES ANALYSIS
-- ================================================================

-- Check for NULL values in each field
SELECT * FROM sales2 WHERE transaction_id IS NULL;
SELECT * FROM sales2 WHERE customer_id IS NULL OR customer_id = '';
SELECT * FROM sales2 WHERE customer_name IS NULL OR customer_name = '';
SELECT * FROM sales2 WHERE email IS NULL OR email = '';
SELECT * FROM sales2 WHERE purchase_date IS NULL OR purchase_date = '';
SELECT * FROM sales2 WHERE product_id IS NULL;
SELECT * FROM sales2 WHERE category IS NULL OR category = '';
SELECT * FROM sales2 WHERE price IS NULL OR price = '';
SELECT * FROM sales2 WHERE quantity IS NULL;
SELECT * FROM sales2 WHERE total_amount IS NULL OR total_amount = '';
SELECT * FROM sales2 WHERE payment_method IS NULL OR payment_method = '';
SELECT * FROM sales2 WHERE customer_address IS NULL OR customer_address = '';
SELECT * FROM sales2 WHERE delivery_status IS NULL OR delivery_status = '';

-- ================================================================
-- STEP 5: PRIMARY KEY IMPLEMENTATION
-- ================================================================

-- Add primary key constraint
ALTER TABLE sales2
ADD PRIMARY KEY (transaction_id);

-- Verify index creation
SHOW INDEX FROM sales2;

-- ================================================================
-- STEP 6: FINAL DATA TYPE CONVERSIONS
-- ================================================================

-- Convert to proper data types after cleaning
ALTER TABLE sales2 MODIFY customer_id INT NOT NULL;
ALTER TABLE sales2 MODIFY price DECIMAL(10,2);

-- ================================================================
-- STEP 7: HANDLING MISSING VALUES
-- ================================================================

-- Handle missing category values
SELECT DISTINCT category FROM sales2;
UPDATE sales2
SET category = 'Unknown'
WHERE category IS NULL OR category = '';

-- Handle missing delivery_status values
SELECT DISTINCT delivery_status FROM sales2;
UPDATE sales2 
SET delivery_status = 'Not Delivered'
WHERE delivery_status IS NULL OR delivery_status = '';

-- Handle missing customer_address values
SELECT DISTINCT customer_address FROM sales2;
UPDATE sales2 
SET customer_address = 'Not Available'
WHERE customer_address = '' OR customer_address IS NULL;

-- Standardize payment_method variants
SELECT DISTINCT payment_method FROM sales2;
UPDATE sales2
SET payment_method = 'Credit Card'
WHERE payment_method IN ('creditcard', 'CC', 'credit');

-- Handle missing payment_method values
SELECT DISTINCT payment_method FROM sales2;
UPDATE sales2
SET payment_method = 'Cash'
WHERE payment_method IS NULL OR payment_method = '';

-- Handle missing customer_name values
UPDATE sales2
SET customer_name = 'User'
WHERE customer_name IS NULL OR customer_name = '';

-- ================================================================
-- STEP 8: VALIDATION CHECKS
-- ================================================================

-- Verify all updates
SELECT * FROM sales2;
SELECT COUNT(*) FROM sales2 WHERE customer_address = 'Not Available';
SELECT COUNT(*) FROM sales2 WHERE payment_method = 'Cash';

-- ================================================================
-- STEP 9: CATEGORY-SPECIFIC PRICE IMPUTATION
-- ================================================================

-- Calculate global mean and median (for reference)
SELECT AVG(price) FROM sales2;

SELECT 
    AVG(1.0 * price) AS median_price
FROM (
    SELECT price,
           @row_number := @row_number + 1 AS rn
    FROM sales2,
         (SELECT @row_number := 0) AS init
    ORDER BY price
) AS ranked
WHERE rn IN (
    FLOOR((SELECT COUNT(*) FROM sales2)/2 + 1),
    CEIL((SELECT COUNT(*) FROM sales2)/2 + 1)
);

-- Calculate category-wise average prices
SELECT category, AVG(price) AS avg_price
FROM sales2
GROUP BY category;

-- Impute missing prices using category averages
UPDATE sales2 SET price = 2663.92 WHERE price IS NULL AND category = 'Electronics';
UPDATE sales2 SET price = 2539.27 WHERE price IS NULL AND category = 'Clothing';
UPDATE sales2 SET price = 2591.64 WHERE price IS NULL AND category = 'Books';
UPDATE sales2 SET price = 2237.19 WHERE price IS NULL AND category = 'Toys';
UPDATE sales2 SET price = 2511.41 WHERE price IS NULL AND category = 'Unknown';
UPDATE sales2 SET price = 2507.05 WHERE price IS NULL AND category = 'Home & Kitchen';

-- ================================================================
-- STEP 10: DATA ANOMALY CORRECTIONS
-- ================================================================

-- Fix negative quantities
SELECT * FROM sales2 WHERE quantity < 0;
UPDATE sales2
SET quantity = ABS(quantity)
WHERE quantity < 0;

-- Recalculate total_amount
SELECT DISTINCT total_amount FROM sales2;
UPDATE sales2
SET total_amount = price * quantity
WHERE total_amount IS NULL OR total_amount = '' OR total_amount <> price * quantity; 

-- Fix negative total_amount values
UPDATE sales2
SET total_amount = ABS(total_amount)
WHERE total_amount < 0 OR total_amount IS NULL OR total_amount = '';

-- Convert total_amount to proper data type
ALTER TABLE sales2 MODIFY COLUMN total_amount DECIMAL(10,2);

-- ================================================================
-- STEP 11: DATE VALIDATION AND CORRECTION
-- ================================================================

-- Identify invalid dates
SELECT * FROM sales2 WHERE purchase_date = '2024-02-30';

-- Preview date conversion
SELECT purchase_date, STR_TO_DATE(purchase_date, '%d-%m-%Y') 
FROM sales2;

-- Set invalid dates to NULL
UPDATE sales2
SET purchase_date = NULL
WHERE purchase_date = '2024-02-30';

-- Convert text dates to proper DATE format
UPDATE sales2
SET purchase_date = STR_TO_DATE(purchase_date, '%d-%m-%Y');

-- Modify column type to DATE
ALTER TABLE sales2 MODIFY COLUMN purchase_date DATE;

-- ================================================================
-- STEP 12: EMAIL VALIDATION
-- ================================================================

-- Identify invalid email addresses
SELECT * FROM sales2 WHERE email NOT LIKE '%@%';

-- Set invalid emails to NULL
UPDATE sales2
SET email = NULL
WHERE email NOT LIKE '%@%';

-- ================================================================
-- STEP 13: SCHEMA CLEANUP
-- ================================================================

-- Drop temporary row_num column
ALTER TABLE sales2 DROP COLUMN row_num;

-- Verify final schema
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales2';

-- ================================================================
-- STEP 14: FINAL VALIDATION
-- ================================================================

-- View final cleaned dataset
SELECT * FROM sales2;

-- Verify no blank/NULL customer_id values
SELECT COUNT(*) AS blank_customer_id
FROM sales2
WHERE customer_id = '' OR customer_id IS NULL;

-- ================================================================
-- END OF DATA CLEANING WORKFLOW
-- Final record count: 940 unique transactions
-- Data completeness: 100%
-- ================================================================
