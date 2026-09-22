-- ============================================================
-- Merchant Risk Intelligence
-- 00_setup.sql
-- Database and table setup
-- ============================================================

-- Create database
CREATE DATABASE merchant_risk_intelligence;

USE merchant_risk_intelligence;

-- ============================================================
-- 1. Merchants
-- One row per merchant
-- ============================================================

CREATE TABLE merchants (
merchant_id INT PRIMARY KEY,
merchant_name VARCHAR(150),
industry VARCHAR(100),
country VARCHAR(100),
onboarding_date DATE,
merchant_status VARCHAR(50)
);

-- ============================================================
-- 2. Monthly Transactions
-- One row per merchant per month
-- ============================================================

CREATE TABLE monthly_transactions (
transaction_id INT PRIMARY KEY,
merchant_id INT,
transaction_month DATE,
transaction_count INT,
transaction_amount DECIMAL(15,2),
refund_amount DECIMAL(15,2),
chargeback_count INT,
FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

-- ============================================================
-- 3. Merchant Risk
-- Monthly risk assessment for each merchant
-- ============================================================

CREATE TABLE merchant_risk (
risk_id INT PRIMARY KEY,
merchant_id INT,
assessment_month DATE,
risk_score DECIMAL(5,2),
risk_level VARCHAR(20),
fraud_rate DECIMAL(7,4),
chargeback_rate DECIMAL(7,4),
FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

-- ============================================================
-- 4. Website Signals
-- Monthly website/operational signals for each merchant
-- ============================================================

CREATE TABLE website_signals (
signal_id INT PRIMARY KEY,
merchant_id INT,
signal_month DATE,
website_downtime_hours DECIMAL(8,2),
traffic_change_pct DECIMAL(7,2),
failed_payment_rate DECIMAL(7,4),
FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

-- ============================================================
-- 5. Business Profile
-- Additional merchant-level business information
-- ============================================================

CREATE TABLE business_profile (
profile_id INT PRIMARY KEY,
merchant_id INT,
annual_revenue DECIMAL(15,2),
employee_count INT,
business_age_years DECIMAL(5,2),
previous_risk_incidents INT,
FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
);

-- ============================================================
-- Setup complete
-- ============================================================
-- The tables created are:
-- merchants
-- monthly_transactions
-- merchant_risk
-- website_signals
-- business_profile
-------------------

-- Data insertion/import can be performed after this setup.
-- ============================================================
