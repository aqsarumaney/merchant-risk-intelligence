# Merchant Risk Intelligence

### Portfolio Assessment, Early Warning & Risk Monitoring

A portfolio analytics case study built around a fictional payments company and synthetic merchant data.

The project demonstrates an end-to-end analytics workflow — from data-quality checks and SQL analysis through Power BI reporting and a quarterly management review.

> **Note:** Nova Payments, the merchants, and all underlying data in this project are fictional and synthetic. This project does not represent Envisso's actual clients, data, risk methodology, or internal processes.

---

## Business Context

Nova Payments is a fictional payments company working with PayFac partners and a portfolio of sub-merchants.

The objective of the analysis was to understand:

- Portfolio composition and concentration
- Transaction exposure
- Merchant and PayFac risk
- Chargeback and fraud indicators
- Merchant outliers
- External risk signals
- Early signs of risk deterioration
- Data-quality issues that could affect reporting

The project was inspired by the type of portfolio and risk-analysis work described in a Data Analyst opportunity I was researching. The company, data and methodology used here are entirely fictional.

---

## Dataset

The synthetic dataset contains:

- **600 merchants**
- **12 months of activity**
- **7,200 merchant-month observations**
- **10 PayFac partners**
- **9 industries**
- Merchant, transaction, risk, website and business-profile information

The raw dataset intentionally contains several data-quality issues to simulate a more realistic analytical environment.

These include:

- Duplicate merchant-month records
- Inconsistent category values
- Invalid negative transaction values
- Missing information

---

## Data Quality & SQL

The project starts with identifying, cleaning and validating the underlying data in MySQL.

The data-quality workflow included:

- Checking the expected grain of each table
- Identifying duplicate merchant-month records
- Standardizing inconsistent industry values
- Identifying and correcting invalid transaction values
- Reviewing missing values
- Validating the cleaned tables before analysis

The SQL analysis then focused on business questions including:

- Portfolio composition
- Industry and geographic concentration
- Transaction exposure
- PayFac performance
- Merchant risk
- Chargeback and fraud rates
- Merchant outliers
- Risk deterioration
- Early-warning indicators
- Multi-signal merchant screening

---

## Power BI

The Power BI report contains five pages:

### 1. Executive Risk Overview

A management-level view of portfolio size, active merchants, overall risk and warning indicators.

### 2. Portfolio & Concentration

Analysis of merchant distribution and transaction exposure across industries, countries and PayFac partners.

### 3. Merchant Risk & Outliers

Analysis of risk distribution, chargeback and fraud indicators, transaction exposure, PayFac risk and persistently elevated merchants.

### 4. Early Warning

Analysis of recent sudden and repeated risk deterioration to identify merchants that may require continued monitoring.

### 5. Merchant Investigation

A drill-through page for investigating an individual merchant, combining merchant profile, transaction exposure, risk trends, operational risk indicators and risk signals.

---

## Quarterly Risk Review

The analysis was also converted into a management-style quarterly risk review.

The review brings together:

- Portfolio overview
- Transaction exposure
- Industry and geographic concentration
- Portfolio risk profile
- Merchant screening
- Early-warning indicators
- Data-quality controls
- Management monitoring priorities

The purpose was to demonstrate how analytical findings can be communicated in a format suitable for a management or risk-review discussion.

---

## Tools

- MySQL
- SQL
- Power BI
- DAX
- Excel
- PowerPoint

AI was used as a learning and productivity aid during the project for brainstorming, syntax support and structuring ideas. Generated suggestions were reviewed rather than assumed to be correct. SQL queries and DAX measures were tested against the dataset, and the final analysis and presentation decisions were reviewed manually.

---

## Repository Structure

```text
merchant-risk-intelligence/
│
├── README.md
│
├── data/
│   ├── raw/
│   │   ├── merchants.csv
│   │   ├── monthly_transactions.csv
│   │   ├── merchant_risk.csv
│   │   ├── website_signals.csv
│   │   └── business_profile.csv
│   │
│   └── cleaned/
│       ├── merchants.csv
│       ├── monthly_transactions.csv
│       ├── merchant_risk.csv
│       ├── website_signals.csv
│       └── business_profile.csv
│
├── sql/
│   ├── 00_setup.sql
│   ├── 01_data_quality_and_cleaning.sql
│   ├── 02_portfolio_analysis.sql
│   ├── 03_merchant_risk_analysis.sql
│   └── 04_early_warning_analysis.sql
│
├── powerbi/
│   └── Merchant_Risk_Intelligence.pbix
│
├── reports/
│   └── Quarterly_Risk_Review_Q4_2024.pdf
│
└── images/
    ├── executive-risk-overview.png
    ├── portfolio-concentration.png
    ├── merchant-risk-outliers.png
    ├── early-warning.png
    └── merchant-investigation.png
