-- ============================================================
-- 01_DATA_QUALITY_AND_CLEANING
-- Merchant Risk Intelligence
-- ============================================================

USE merchant_risk_intelligence;


-- ============================================================
-- 1. DUPLICATE CHECKS
-- Expected grain:
-- merchants: 1 row per merchant
-- monthly_transactions: 1 row per merchant-month
-- merchant_risk: 1 row per merchant-month
-- website_signals: 1 row per merchant
-- business_profile: 1 row per merchant
-- ============================================================

-- Check for duplicate merchant IDs
SELECT merchant_id, COUNT(*) AS row_count
FROM merchants
GROUP BY merchant_id
HAVING COUNT(*) > 1;

-- Check for duplicate merchant-month records
SELECT merchant_id, month, COUNT(*) AS row_count
FROM monthly_transactions
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;

SELECT merchant_id, month, COUNT(*) AS row_count
FROM merchant_risk
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;

-- Check for duplicate merchant IDs
SELECT merchant_id, COUNT(*) AS row_count
FROM website_signals
GROUP BY merchant_id
HAVING COUNT(*) > 1;

SELECT merchant_id, COUNT(*) AS row_count
FROM business_profile
GROUP BY merchant_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 2. DUPLICATE RECORD INSPECTION
-- Inspect the duplicate merchant-month records before cleaning.
-- ============================================================

SELECT *
FROM monthly_transactions mt
JOIN (
    SELECT merchant_id, month, COUNT(*) AS row_count
    FROM monthly_transactions
    GROUP BY merchant_id, month
    HAVING COUNT(*) > 1
) d
ON mt.merchant_id = d.merchant_id
AND mt.month = d.month
ORDER BY mt.merchant_id, mt.month;


SELECT *
FROM merchant_risk mr
JOIN (
    SELECT merchant_id, month, COUNT(*) AS row_count
    FROM merchant_risk
    GROUP BY merchant_id, month
    HAVING COUNT(*) > 1
) d
ON mr.merchant_id = d.merchant_id
AND mr.month = d.month
ORDER BY mr.merchant_id, mr.month;


-- ============================================================
-- 3. DUPLICATE CLEANING
-- Exact duplicate rows were identified in the two
-- merchant-month tables. SELECT DISTINCT retains one copy
-- of each unique record.
-- ============================================================

CREATE TABLE monthly_transactions_clean AS
SELECT DISTINCT *
FROM monthly_transactions;

DROP TABLE monthly_transactions;

RENAME TABLE monthly_transactions_clean TO monthly_transactions;


CREATE TABLE merchant_risk_clean AS
SELECT DISTINCT *
FROM merchant_risk;

DROP TABLE merchant_risk;

RENAME TABLE merchant_risk_clean TO merchant_risk;

-- Finding:
-- Duplicate merchant-month records were identified in
-- monthly_transactions and merchant_risk. The duplicate rows
-- were exact duplicates and were removed using SELECT DISTINCT.


-- ============================================================
-- 4. DUPLICATE VALIDATION
-- Confirm that no duplicate merchant-month records remain.
-- ============================================================

SELECT merchant_id, month, COUNT(*) AS row_count
FROM monthly_transactions
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;

SELECT merchant_id, month, COUNT(*) AS row_count
FROM merchant_risk
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;


-- ============================================================
-- 5. NULL VALUE CHECK
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM merchants
     WHERE country IS NULL) AS country_nulls,

    (SELECT COUNT(*) FROM merchants
     WHERE delivery_days IS NULL) AS delivery_days_nulls,

    (SELECT COUNT(*) FROM website_signals
     WHERE reputation_score IS NULL) AS reputation_score_nulls,

    (SELECT COUNT(*) FROM business_profile
     WHERE company_age_years IS NULL) AS company_age_years_nulls,

    (SELECT COUNT(*) FROM business_profile
     WHERE ownership_flag IS NULL) AS ownership_flag_nulls;


-- Finding:
-- NULL values were found in country, delivery_days,
-- reputation_score, company_age_years, and ownership_flag.
-- These values were retained because they represent unavailable
-- information and there was insufficient evidence for defensible
-- imputation.


-- ============================================================
-- 6. INCONSISTENT CATEGORY CHECK
-- Check industry values for inconsistent formatting,
-- including trailing spaces and capitalization.
-- ============================================================

SELECT
    industry,
    LENGTH(industry) AS industry_length,
    COUNT(*) AS row_count
FROM merchants
GROUP BY industry
ORDER BY industry;


-- ============================================================
-- 7. CATEGORY CLEANING
-- Standardize the two identified Retail values.
-- ============================================================

UPDATE merchants
SET industry = 'Retail'
WHERE merchant_id IN ('M0351', 'M0384');

-- Finding:
-- Two inconsistent Retail values were identified: one with a
-- trailing space and one with different capitalization.
-- Both were standardized to 'Retail'.

-- ============================================================
-- 8. CATEGORY VALIDATION
-- ============================================================

SELECT
    industry,
    LENGTH(industry) AS industry_length,
    COUNT(*) AS row_count
FROM merchants
GROUP BY industry
ORDER BY industry;


-- ============================================================
-- 9. INVALID NUMERIC VALUE CHECK
-- Transaction count and transaction volume should not
-- contain negative values.
-- ============================================================

SELECT *
FROM monthly_transactions
WHERE transaction_count < 0
   OR transaction_volume < 0;


-- ============================================================
-- 10. INVALID VALUE CLEANING
-- Four invalid negative values were identified.
-- The negative signs were removed using ABS() because
-- transaction counts and volumes represent non-negative
-- quantities.
-- ============================================================

UPDATE monthly_transactions
SET transaction_count = ABS(transaction_count)
WHERE (merchant_id, month) IN (
    ('M0099', '2024-04'),
    ('M0268', '2024-12')
);

UPDATE monthly_transactions
SET transaction_volume = ABS(transaction_volume)
WHERE (merchant_id, month) IN (
    ('M0181', '2024-03'),
    ('M0554', '2024-02')
);

-- Finding:
-- Four invalid negative transaction values were identified.
-- The negative signs were removed using ABS() because transaction
-- counts and transaction volume represent non-negative quantities.

-- ============================================================
-- 11. FINAL VALIDATION
-- Confirm that no duplicate or negative transaction records
-- remain after cleaning.
-- ============================================================

SELECT merchant_id, month, COUNT(*) AS row_count
FROM monthly_transactions
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;

SELECT merchant_id, month, COUNT(*) AS row_count
FROM merchant_risk
GROUP BY merchant_id, month
HAVING COUNT(*) > 1;

SELECT *
FROM monthly_transactions
WHERE transaction_count < 0
   OR transaction_volume < 0;
   
-- ============================================================
-- END CONCLUSION
-- ============================================================
-- Data-quality checks identified exact duplicate merchant-month
-- records, missing values, inconsistent industry formatting,
-- and four invalid negative transaction values.
-- Duplicate records were removed, inconsistent Retail values were
-- standardized, and invalid negative transaction values were
-- corrected using ABS().
-- Missing values were retained where the underlying information
-- was unavailable and could not be defensibly imputed.
-- Final validation confirmed that no duplicate merchant-month
-- records or negative transaction values remained.
-- The cleaned data is ready for portfolio and merchant-risk analysis.