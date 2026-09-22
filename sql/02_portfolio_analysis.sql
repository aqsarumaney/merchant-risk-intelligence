-- ============================================================
-- 1. PORTFOLIO SIZE AND ACTIVE MERCHANTS
-- Establish the total number of merchants and identify how
-- many are currently active.
-- ============================================================

SELECT 
    COUNT(*) AS total_merchants,
    SUM(CASE 
            WHEN merchant_status = 'Active' THEN 1 
            ELSE 0 
        END) AS total_active
FROM merchants;

--Finding: 600 merchants in total; 567 are active (94.5%).

-- ============================================================
-- 2. MERCHANT DISTRIBUTION BY INDUSTRY
-- Understand how the merchant portfolio is distributed across
-- industries and identify areas of portfolio concentration.
-- ============================================================

SELECT
    industry,
    COUNT(*) AS total_merchants
FROM merchants
GROUP BY industry
ORDER BY total_merchants DESC;

-- Finding:
-- Retail is the largest industry with 114 merchants (19%).
-- The four largest industries account for 342 merchants (57%)
-- of the total portfolio, indicating moderate industry
-- concentration.

-- ============================================================
-- 3. MERCHANT DISTRIBUTION BY COUNTRY
-- Which countries have the largest merchant concentration?
-- ============================================================

SELECT 
    country, 
    COUNT(*) AS total_merchants
FROM merchants
GROUP BY country
ORDER BY total_merchants DESC;

-- Finding:
-- The United States has the largest merchant concentration with 137 merchants,
-- followed by the United Kingdom with 81. 3 merchants have missing country information.

-- ============================================================
-- 4. MERCHANT DISTRIBUTION BY PAYFAC
-- Which PayFacs manage the largest number of merchants?
-- ============================================================

SELECT 
    payfac_id, 
    COUNT(*) AS total_merchants
FROM merchants
GROUP BY payfac_id
ORDER BY total_merchants DESC;

-- Finding:
-- PF01 and PF02 manage the largest merchant portfolios with 99 and 97 merchants,
-- respectively, while PF10 manages the fewest with 28 merchants.

-- ============================================================
-- 5. MONTHLY TRANSACTION VOLUME TREND
-- How has transaction volume changed month over month?
-- ============================================================

WITH new AS (
    SELECT 
        month, 
        SUM(transaction_volume) AS T_trans_vol
    FROM monthly_transactions
    GROUP BY month
)
SELECT 
    month, 
    T_trans_vol, 
    LAG(T_trans_vol) OVER (ORDER BY month ASC) AS Prev_month_vol,
    T_trans_vol - LAG(T_trans_vol) OVER (ORDER BY month ASC) AS Month_Over_month_change
FROM new;

-- Finding:
-- Transaction volume generally increased through August, declined sharply in September
-- and October, then recovered in November and December, with the largest MoM increase in December.

-- ============================================================
-- 6A. TRANSACTION VOLUME BY PAYFAC
-- Which PayFacs generate the highest transaction volume?
-- ============================================================

SELECT 
    payfac_id, 
    SUM(mt.transaction_volume) AS T_Trans_Vol
FROM merchants AS m
JOIN monthly_transactions AS mt
    ON m.merchant_id = mt.merchant_id
GROUP BY payfac_id
ORDER BY T_Trans_Vol DESC;

-- Finding:
-- PF02 generates the highest transaction volume at approximately $177.4M,
-- while PF06 generates the lowest at approximately $54.5M.

-- ============================================================
-- 6B. TRANSACTION VOLUME BY INDUSTRY
-- Which industries generate the highest transaction volume?
-- ============================================================

SELECT 
    industry, 
    SUM(mt.transaction_volume) AS T_Trans_Vol
FROM merchants AS m
JOIN monthly_transactions AS mt
    ON m.merchant_id = mt.merchant_id
GROUP BY industry
ORDER BY T_Trans_Vol DESC;

-- Finding:
-- Travel generates the highest transaction volume at approximately $340.3M,
-- while Digital Services generates the lowest at approximately $20.9M.

-- ============================================================
-- 7. RISK DISTRIBUTION ACROSS THE PORTFOLIO
-- How is risk distributed across the portfolio?
-- ============================================================

USE merchant_risk_intelligence;

WITH New AS (
    SELECT 
        merchant_id,
        month,
        risk_score,
        CASE 
            WHEN risk_score >= 66 THEN 'High'
            WHEN risk_score >= 31 THEN 'Mid'
            ELSE 'Low'
        END AS Risk_Band
    FROM merchant_risk
)
SELECT 
    Risk_Band,
    COUNT(*) AS Merchant_month_count
FROM New
GROUP BY Risk_Band;

-- Finding:
-- Most merchant-month observations were classified as Low risk (6,662),
-- followed by Mid risk (509) and High risk (29).

-- ============================================================
-- 8. RELATIONSHIP BETWEEN TRANSACTION VOLUME AND RISK
-- Are higher transaction volumes associated with higher risk?
-- ============================================================

USE merchant_risk_intelligence;

WITH new AS (
    SELECT 
        mt.merchant_id,
        AVG(mt.transaction_volume) AS Avg_Vol,
        AVG(mr.risk_score) AS Ave_risk
    FROM monthly_transactions AS mt
    JOIN merchant_risk AS mr
        ON mt.merchant_id = mr.merchant_id
        AND mt.month = mr.month
    GROUP BY mt.merchant_id
),
correlation_values AS (
    SELECT
        COUNT(*) AS n,
        SUM(Avg_Vol) AS sum_x,
        SUM(Ave_risk) AS sum_y,
        SUM(Avg_Vol * Ave_risk) AS sum_xy,
        SUM(Avg_Vol * Avg_Vol) AS sum_x2,
        SUM(Ave_risk * Ave_risk) AS sum_y2
    FROM new
)
SELECT
    (
        n * sum_xy - sum_x * sum_y
    ) /
    SQRT(
        (n * sum_x2 - sum_x * sum_x) *
        (n * sum_y2 - sum_y * sum_y)
    ) AS correlation
FROM correlation_values;

-- Finding:
-- The correlation between average transaction volume and average risk score
-- is approximately 0.02, indicating very little linear association between them. No meaningful relationship was observed.

-- ============================================================
-- 9A. AVERAGE RISK SCORE BY INDUSTRY
-- Which industries have higher average risk scores?
-- ============================================================

SELECT 
    m.industry, 
    AVG(mr.risk_score) AS Average_risk
FROM merchants AS m
JOIN merchant_risk AS mr
    ON m.merchant_id = mr.merchant_id
GROUP BY m.industry
ORDER BY Average_risk DESC;

-- Finding:
-- Hospitality has the highest average risk score (24.22),
-- while Digital Services has the lowest (18.37).

-- ============================================================
-- 9B. AVERAGE RISK SCORE BY COUNTRY
-- Which countries have higher average risk scores?
-- ============================================================

USE merchant_risk_intelligence;

SELECT 
    m.country, 
    AVG(mr.risk_score) AS Average_risk
FROM merchants AS m
JOIN merchant_risk AS mr
    ON m.merchant_id = mr.merchant_id
GROUP BY m.country
ORDER BY Average_risk DESC;

-- Finding:
-- Nigeria has the highest average risk score (25.47),
-- while France has the lowest (18.09).
-- 3 merchants have missing country information, with an average
-- risk score of 21.61.

-- ============================================================
-- 10A. MERCHANT VOLUME BANDS
-- Which merchants fall into Low, Medium, and High transaction
-- volume based on their average monthly transaction volume?
-- ============================================================

WITH merchant_volume AS (
    SELECT 
        merchant_id,
        AVG(transaction_volume) AS Avg_Vol
    FROM monthly_transactions
    GROUP BY merchant_id
),
ordered_volume AS (
    SELECT
        merchant_id,
        Avg_Vol,
        ROW_NUMBER() OVER (ORDER BY Avg_Vol) AS rn,
        COUNT(*) OVER () AS total_merchants
    FROM merchant_volume
),
percentiles AS (
    SELECT
        MIN(CASE 
                WHEN rn = CEIL(total_merchants * 0.25) 
                THEN Avg_Vol 
            END) AS P25,
        MIN(CASE 
                WHEN rn = CEIL(total_merchants * 0.75) 
                THEN Avg_Vol 
            END) AS P75
    FROM ordered_volume
)
SELECT
    CASE
        WHEN mv.Avg_Vol < p.P25 THEN 'Low Volume'
        WHEN mv.Avg_Vol <= p.P75 THEN 'Medium Volume'
        ELSE 'High Volume'
    END AS Volume_Band,
    COUNT(*) AS Merchant_Count
FROM merchant_volume AS mv
CROSS JOIN percentiles AS p
GROUP BY Volume_Band
ORDER BY Merchant_Count DESC;

-- Finding:
-- P25 average monthly transaction volume is $10,746.59 and P75 is $99,956.53.
-- The portfolio contains 149 Low Volume merchants, 301 Medium Volume
-- merchants, and 150 High Volume merchants.

-- ============================================================
-- 10B. HIGH-VOLUME AND HIGH-RISK MERCHANTS
-- Which merchants stand out as both high-volume and higher-risk
-- within the portfolio?
-- ============================================================

WITH merchant_metrics AS (
    SELECT
        merchant_id,
        AVG(transaction_volume) AS Avg_Vol,
        (
            SELECT AVG(risk_score)
            FROM merchant_risk mr
            WHERE mr.merchant_id = mt.merchant_id
        ) AS Avg_Risk
    FROM monthly_transactions mt
    GROUP BY merchant_id
)
SELECT
    mm.merchant_id,
    m.industry,
    m.payfac_id,
    mm.Avg_Vol,
    mm.Avg_Risk
FROM merchant_metrics AS mm
JOIN merchants AS m
    ON mm.merchant_id = m.merchant_id
WHERE mm.Avg_Vol > 99956.528333
  AND mm.Avg_Risk >= 22.6667
ORDER BY mm.Avg_Risk DESC;

-- Finding:
-- 41 merchants have both high average monthly transaction volume
-- (above the portfolio P75 of $99,956.53) and average risk scores
-- at or above the portfolio P75 of 22.67.
-- Several merchants show substantially elevated average risk scores,
-- including M0350 (64.17), M0424 (62.00), and M0280 (53.33),
-- making them candidates for further investigation.


-- ============================================================
-- END CONCLUSION
-- ============================================================
-- The portfolio contains 600 merchants, with 94.5% currently active.
-- Merchant concentration is highest in Retail, while transaction
-- volume is highest in Travel, showing that merchant count and
-- transaction exposure are not necessarily concentrated in the
-- same industries.
-- Transaction volume generally increased through August, declined
-- in September and October, and recovered in November and December.
-- Overall risk was concentrated in the Low-risk band, and average
-- transaction volume showed very little linear association with
-- average risk score.
-- A smaller group of merchants combined high transaction volume
-- with higher-than-portfolio-average risk scores, providing
-- candidates for further investigation.




