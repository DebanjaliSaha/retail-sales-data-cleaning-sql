# Retail Sales Data Cleaning Using SQL

## Project Overview:
This project demonstrates a comprehensive data cleaning workflow on a retail sales dataset using MySQL. The original dataset contained 1004 transaction records, but upon import into MySQL, only 943 records were loaded. After systematic data cleaning techniques, the dataset was transformed into 940 analysis-ready records with 100% data integrity.
## Objectives:
- Remove duplicate records while preserving data integrity
- Handle missing values using context-aware imputation strategies
- Standardize categorical variables for consistency
- Validate and correct data anomalies (dates, emails, calculations)
- Enforce proper data types and constraints
- Prepare a clean, analysis-ready dataset for business intelligence

## Dataset Information

**Original Dataset:**

- Records: 1004 transactions
- Imported Records: 943 transactions
- Fields: 13 columns
- Source: Retail sales database

**Fields:**

- `transaction_id` - Unique transaction identifier
- `customer_id` - Customer identifier
- `customer_name` - Customer full name
- `email` - Customer email address
- `purchase_date` - Date of transaction
- `product_id` - Product identifier
- `category` - Product category
- `price` - Unit price of product
- `quantity` - Quantity purchased
- `total_amount` - Total transaction amount
- `payment_method` - Payment type used
- `delivery_status` - Order delivery status
- `customer_address` - Customer address

## Repository Structure
```
sales-data-cleaning/
│
├── data/
│   ├── raw_sales_data.csv          # Original dataset
│   └── cleaned_sales_data.csv       # Final cleaned dataset
│
├── scripts/
│   └── data_cleaning_queries.sql    # All SQL cleaning queries
│
├── analysis/
│   └── exploratory_analysis.sql     # Post-cleaning analysis queries
│
└── README.md                         # Project documentation
```
## How to Reproduce This Project
**Prerequisites:**

- MySQL 8.0 or higher
- MySQL Workbench or command-line access

**Steps:**

**Clone the repository**
```
bashgit clone https://github.com/yourusername/sales-data-cleaning.git
cd sales-data-cleaning
```
**Create database and import data**
```
CREATE DATABASE sales;
USE sales;
```
**Import the raw dataset**
```
bashmysql -u username -p sales < data/raw_sales_data.sql
```
**Run the cleaning script**
```
bashmysql -u username -p sales < scripts/data_cleaning_queries.sql
```
**Verify results**
```
SELECT COUNT(*) FROM sales2;
-- Note: sales2 is the cleaned table created during the cleaning process
-- while sales remains the original raw data.
```

## 🔍 Data Quality Issues Identified

### 1. Duplicate Records
- **3 duplicate transactions** found based on `transaction_id` and `customer_id` combination

### 2. Missing Values Analysis

Conducted systematic NULL and blank value checks across all 13 fields:

**Fields with NO Missing Values (0 NULL/blank rows):**
- ✅ `transaction_id` - Primary identifier, no NULLs
- ✅ `customer_id` - Complete data, 0 NULL/blank rows
- ✅ `purchase_date` - Complete data, 0 NULL/blank rows (but contained invalid dates like Feb 30th)
- ✅ `product_id` - Complete data, 0 NULL/blank rows
- ✅ `price` - Complete data, 0 NULL/blank rows (still required category-specific validation)
- ✅ `quantity` - Complete data, 0 NULL/blank rows (but contained negative values requiring correction)
- ✅ `email` - Complete data, 0 NULL/blank rows (but 189 rows had improperly formatted emails without '@' symbol)

**Fields with Missing Values:**

| Field | NULL/Blank Rows |
|-------|----------------|
| `customer_name` | **50** |
| `customer_address` | **52** |
| `delivery_status` | **125** |
| `payment_method` | **129** |
| `category` | **153** |
| `total_amount` | **189** |

**Total Missing Values:** 698 cells across 6 fields

### 3. Data Anomalies

Despite some fields showing 0 NULL values, they still contained critical data quality issues:

- **Invalid dates:** Records with impossible dates (e.g., February 30th, 2024)
- **Negative quantities:** Transaction quantities had negative values despite complete data
- **Email formatting issues:** 189 records with improperly formatted emails (missing '@' symbol)
- **Calculation errors:** `total_amount` didn't match `price × quantity` in multiple records
- **Inconsistent pricing:** Required category-specific validation despite no NULL price values

### 4. Formatting Inconsistencies
- **Payment methods:** 4 inconsistent variants ('creditcard', 'CC', 'credit', 'Credit Card')
- **Data types:** Text stored in numeric fields
- **Date formats:** Dates stored as text instead of DATE type

## 🛠️ Data Cleaning Process

### Step 1: Initial Data Exploration
Performed initial SELECT queries to understand the dataset structure and identify data quality issues across all 13 fields.

### Step 2: Duplicate Detection and Removal

**Approach:**
- Used `ROW_NUMBER()` window function with `PARTITION BY transaction_id, customer_id`
- Created a Common Table Expression (CTE) to identify duplicates
- Verified duplicate records for transactions 1001, 1004, and 1030

**Execution:**
- Created a new table `sales2` with an additional `row_num` column
- Inserted all records with row numbers assigned
- Deleted records where `row_num > 1`, removing 3 duplicate entries

**Result:** Reduced dataset from 943 to 940 unique records

### Step 3: Data Type Modifications

**Initial Modifications:**
- Modified `customer_id` to VARCHAR(255) to handle potential NULL values during cleaning
- Modified `price` to VARCHAR(255) for temporary handling of missing values

**Final Type Conversions:**
- `customer_id`: Converted to INT NOT NULL after cleaning
- `price`: Converted to DECIMAL(10,2) for precise currency representation
- `total_amount`: Converted to DECIMAL(10,2)
- `purchase_date`: Converted to DATE type after format standardization

### Step 4: Primary Key Implementation

**Action:**
- Added `PRIMARY KEY` constraint on `transaction_id`
- Verified index creation using `SHOW INDEX`

**Purpose:** Ensure unique transaction identification and prevent future duplicates

### Step 5: Handling Missing Values

#### Customer Name (50 NULL/blank rows)
**Solution:** Updated NULL/blank values to **'User'** as placeholder

**Result:** 100% populated

#### Category (153 NULL/blank rows)
**Solution:** Updated NULL/blank values to **'Unknown'**

**Result:** All records categorized

#### Delivery Status (125 NULL/blank rows)
**Solution:** Updated NULL/blank values to **'Not Delivered'**

**Result:** Clear delivery tracking for all records

#### Customer Address (52 NULL/blank rows)
**Solution:** Set NULL/blank values to **'Not Available'**

**Result:** Explicit indication of missing address data

#### Payment Method (129 NULL/blank rows)

**Problem:** Found 4 inconsistent variants representing credit card payments:
- 'creditcard'
- 'CC'
- 'credit'
- 'Credit Card'

**Solution:**
1. First, standardized all 4 variants to **'Credit Card'**
2. Then, assigned remaining 129 NULL/blank values to **'Cash'** (default payment method)

**Result:** Achieved categorical consistency with standardized payment categories

#### Total Amount (189 NULL/blank rows)
**Solution:** Recalculated using formula: `total_amount = price × quantity`

**Result:** 100% accurate financial calculations

### Step 6: Category-Specific Price Imputation

**Strategy:** Instead of using a global mean/median, calculated category-wise average prices to preserve business context.

**Analysis:**

- Electronics:     ₹2,663.92
- Clothing:        ₹2,539.27
- Books:           ₹2,591.64
- Toys:            ₹2,237.19
- Home & Kitchen:  ₹2,507.05
- Unknown:         ₹2,511.41

**Implementation:**

- Grouped by category and calculated AVG(price) for each category
- Updated NULL price values with respective category averages
- This approach maintains pricing patterns specific to product types

**Rationale:** Electronics naturally have higher average prices than toys, so category-specific imputation maintains realistic pricing structure rather than pulling all categories toward a single global mean.
### Step 7: Data Anomaly Corrections

#### Negative Quantities
**Issue:** Some transaction records had negative quantity values despite 0 NULL rows

**Solution:**
- Identified records with quantity < 0
- Applied ABS() function to convert to positive values
- Maintains transaction volume accuracy

**Result:** ✅ All quantities corrected to positive values

#### Invalid Dates
**Issue:** Found records with impossible dates (e.g., '2024-02-30') despite 0 NULL rows

**Solution:**
- Identified invalid dates using STR_TO_DATE() function
- Set invalid dates to NULL
- Converted all valid dates from text format ('%d-%m-%Y') to proper DATE type
- Modified column type to DATE for database-level validation

**Result:** ✅ 100% valid date entries

#### Email Validation (189 improperly formatted)
**Issue:** 189 records contained improperly formatted email addresses (missing '@' symbol) despite 0 NULL rows

**Solution:**
- Identified emails NOT LIKE '%@%'
- Set invalid emails to NULL for data integrity
- Prevents downstream issues in email communication systems

**Result:** ✅ All remaining emails properly formatted

#### Total Amount Recalculation
**Issue:** Many records had total_amount values that didn't match price × quantity

**Solution:**
- Recalculated total_amount = price × quantity for all records
- Handled NULL and blank values
- Applied ABS() to correct negative total amounts
- Ensures financial calculation accuracy

**Result:** ✅ 100% accurate financial calculations

### Step 8: Schema Cleanup
**Actions:**

- Dropped the temporary row_num column used for duplicate detection.
- Verified final schema using INFORMATION_SCHEMA.COLUMNS.

**Final Validation:**

- Confirmed all columns have proper data types.
- Verified no blank/NULL customer_id values remain.

## 📈 Results and Impact

### Quantitative Outcomes

| Metric                    | Before         | After | Impact                                      |
|---------------------------|----------------|-------|---------------------------------------------|
| Total Records             | 943 (imported) | 940   | 3 duplicates removed                        |
| Data Completeness         | ~85%           | 100%  | 698 missing values resolved                 |
| Missing `customer_name`   | 50             | 0     | Updated to 'User'                           |
| Missing `category`        | 153            | 0     | Updated to 'Unknown'                        |
| Missing `total_amount`    | 189            | 0     | Recalculated as price × quantity            |
| Missing `payment_method`  | 129            | 0     | Standardized to 'Credit Card' / 'Cash'      |
| Missing `delivery_status` | 125            | 0     | Updated to 'Not Delivered'                  |
| Missing `customer_address`| 52             | 0     | Updated to 'Not Available'                  |
| Email Validity            | 189 invalid    | All valid or NULL | Email format validation applied      |
| Date Integrity            | Invalid dates  | 100% valid | Date format standardization            |
| Calculation Accuracy      | Mismatched     | 100% accurate | Total amount recalculated            |
| Categorical Consistency   | 4 variants     | 2 categories | Standardized payment nomenclature    |


**Key Achievements**
- ✅**100% Data Completeness** - All critical fields populated or explicitly marked as unavailable
- ✅**Zero Duplicates** - Removed 3 duplicate transactions using window functions
- ✅**Standardized Categories** - Consolidated 4 payment method variants into 2 consistent categories
- ✅**Corrected Anomalies** - Fixed invalid dates, negative quantities, 189 emails, and financial calculations.
- ✅**Business-Aware Imputation** - Category-specific pricing maintains product segment characteristics
- ✅**Production-Ready** - Proper constraints, data types, and validation rules in place

## 🔧 Technical Skills Demonstrated

**SQL Techniques:**

- Window Functions: ROW_NUMBER() OVER(PARTITION BY ... ORDER BY ...)
- Common Table Expressions (CTEs): For complex duplicate detection logic
- Data Type Conversions: VARCHAR → INT, TEXT → DATE, TEXT → DECIMAL
- Aggregate Functions: AVG(), COUNT(), ABS()
- String Functions: STR_TO_DATE(), LIKE pattern matching
- Schema Modifications: ALTER TABLE, ADD PRIMARY KEY, MODIFY COLUMN
- Conditional Updates: WHERE clauses with multiple conditions (NULL, blank, invalid values)

**Tools Used:**

- MySQL: Primary database management system
- SQL Workbench/CLI: Query execution and testing

## Key Insights
1. **Context-Aware Imputation Matters**
Category-specific averages (Electronics: ₹2663, Toys: ₹2237) preserve natural pricing structures better than global means.
2. **Complete Data ≠ Clean Data**
Fields with 0 NULLs still required validation—189 emails lacked '@' symbols, quantities had negatives, dates were impossible.
3. **Standardization Enables Analysis**
Consolidating 4 payment variants into 2 categories simplifies downstream reporting and analytics.
4. **Window Functions Solve Complex Problems**
ROW_NUMBER() with PARTITION BY elegantly handled duplicate detection without complex joins.

## Next Steps
- Sales Trend Analysis: Analyze sales patterns by category, time period, and payment method
- Customer Segmentation: Group customers based on purchasing behavior and demographics
- Revenue Forecasting: Build predictive models using the cleaned historical data
- Product Performance Analysis: Identify top-performing products and categories
- Delivery Optimization: Analyze delivery status patterns to improve logistics

## Conclusion
This project successfully transformed a messy retail sales dataset with multiple data quality issues into a clean, analysis-ready database. The original dataset contained 1004 records, but only 943 were imported into MySQL. Through systematic application of SQL techniques including window functions, CTEs, type conversions, and context-aware imputation strategies, the dataset achieved 100% data integrity while preserving business context.
The cleaned dataset of 940 records is now ready for advanced analytics, reporting, and machine learning applications, demonstrating the critical role of thorough data cleaning in the data analysis pipeline.

 ## Acknowledgments
**Dataset Source:**

Dataset: Retail Sales Dataset
Source: Ankit Raj Mishra's GitHub Repository
Original video tutorial: Data Cleaning Project by Ankit Raj Mishra

**Learning Resources:**

Primary Tutorial: MySQL Data Cleaning Project - Ankit Raj Mishra[https://www.youtube.com/watch?v=tvCTy-8YUFY&t=3s]
Additional Reference: Data Cleaning in SQL - Alex The Analyst[https://www.youtube.com/watch?v=4UltKCnnnTA&t=77s]
Documentation: MySQL 8.0 Official Documentation

*Note:* 
This project was completed as a hands-on learning exercise based on Ankit Raj Mishra's MySQL data cleaning tutorial. While following the tutorial structure, I independently implemented each SQL technique, created comprehensive documentation with detailed explanations, and analyzed the business impact of each cleaning decision. Additional data cleaning concepts were learned from Alex The Analyst's tutorial series.

