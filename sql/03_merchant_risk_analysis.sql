-- ============================================================
-- 1. OVERALL MERCHANT RISK PROFILE
-- What is the overall risk level of the merchant portfolio?
-- ============================================================

-- Merchant-level risk profile
SELECT 
    merchant_id, 
    AVG(risk_score) AS Avg_riskscore, 
    MAX(risk_score) AS Max_score,
    MIN(risk_score) AS Min_score
FROM merchant_risk
GROUP BY merchant_id;


-- Distribution of merchants by average annual risk band
WITH New AS (
    SELECT 
        merchant_id,
        CASE 
            WHEN AVG(risk_score) <= 30 THEN 'Low AvgRisk'
            WHEN AVG(risk_score) <= 65 THEN 'Mid AvgRisk'
            ELSE 'High AvgRisk'
        END AS Avg_RiskBand
    FROM merchant_risk
    GROUP BY merchant_id
)
SELECT 
    Avg_RiskBand, 
    COUNT(*) AS T_Merchants
FROM New
GROUP BY Avg_RiskBand;


-- Finding:
-- 556 merchants (92.7%) have a low average annual risk score,
-- 43 merchants (7.2%) fall into the mid-risk band,
-- and 1 merchant (0.2%) falls into the high-risk band.
-- Overall, the portfolio is predominantly low risk based on
-- merchants' average annual risk scores, with a small group
-- showing persistently elevated average risk.

-- ============================================================
-- 2. MERCHANTS WITH PERSISTENTLY ELEVATED RISK
-- Which merchants have the highest average risk across the year?
-- ============================================================

SELECT  
    merchant_id,
    AVG(risk_score) AS Avg_risk
FROM merchant_risk
GROUP BY merchant_id
ORDER BY Avg_risk DESC;

-- Finding:
-- The highest average risk scores are concentrated among a small
-- group of merchants. M0257 has the highest average risk score
-- (65.42), followed by M0350 (64.17), M0407 (63.50),
-- M0424 (62.00), and M0141 (61.08).
-- These merchants are candidates for further investigation.

-- ============================================================
-- 3A. RISK CHANGE FROM JANUARY TO DECEMBER
-- Which merchants had a higher risk score at the end of the year
-- compared with the beginning of the year?
-- ============================================================

WITH New AS (
    SELECT 
        merchant_id,
        FIRST_VALUE(risk_score) OVER (
            PARTITION BY merchant_id 
            ORDER BY month ASC
        ) AS FirstValue,
        LAST_VALUE(risk_score) OVER (
            PARTITION BY merchant_id 
            ORDER BY month ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS LastValue
    FROM merchant_risk
)
SELECT DISTINCT
    merchant_id,
    FirstValue,
    LastValue,
    LastValue - FirstValue AS TChange
FROM New
ORDER BY TChange DESC;

-- Finding:
-- Several merchants showed substantial increases in risk between
-- January and December. The largest increase was M0055, whose
-- risk score rose from 12 to 60 (+48), followed by M0075 (+42)
-- and M0281 (+40).
-- This identifies merchants whose year-end risk was materially
-- higher than their starting risk, but does not by itself prove
-- a sustained deterioration throughout the year.

-- ============================================================
-- 3B. SUSTAINED MONTH-TO-MONTH RISK INCREASES
-- Which merchants experienced repeated increases in risk during
-- the year?
-- ============================================================

WITH New AS (
    SELECT 
        merchant_id,
        risk_score,
        LAG(risk_score) OVER (
            PARTITION BY merchant_id 
            ORDER BY month ASC
        ) AS Prevmonth
    FROM merchant_risk
),
New2 AS (
    SELECT 
        merchant_id,
        risk_score - Prevmonth AS Difference
    FROM New
)
SELECT 
    merchant_id,
    COUNT(*) AS TIncMonth
FROM New2
WHERE Difference > 0
GROUP BY merchant_id
HAVING TIncMonth > 6
ORDER BY TIncMonth DESC;


-- Finding:
-- 64 merchants experienced risk increases in more than 6 of the
-- 11 month-to-month comparisons, indicating repeated upward
-- movement in risk during the year.
-- M0055, M0070, M0338, M0376, and M0474 each recorded risk
-- increases in 9 of 11 comparisons, indicating particularly
-- consistent upward movement.

-- ============================================================
-- 4. SUDDEN RISK DETERIORATION
-- Which merchants experienced large month-to-month increases
-- in risk?
-- ============================================================

WITH New AS (
    SELECT 
        merchant_id,
        month,
        risk_score,
        LAG(risk_score) OVER (
            PARTITION BY merchant_id 
            ORDER BY month ASC
        ) AS Prevmonth
    FROM merchant_risk
)
SELECT
    merchant_id,
    month,
    Prevmonth,
    risk_score,
    risk_score - Prevmonth AS Risk_Change
FROM New
WHERE risk_score - Prevmonth >= 15
ORDER BY Risk_Change DESC;

-- Finding:
-- 20 sudden risk deterioration events were identified using a
-- screening threshold of a +15 or greater month-to-month increase.
-- The largest increases were M0075 and M0496 (+31 each) in August,
-- followed by M0281 (+30) and M0532 (+25).
-- M0496 experienced two separate sudden deterioration events,
-- indicating repeated sharp changes during the year.
-- These merchants and events are candidates for further investigation.

-- ============================================================
-- 5. UNUSUALLY HIGH CHARGEBACK AND FRAUD ACTIVITY
-- Which merchants have unusually high chargeback or fraud rates
-- relative to the rest of the portfolio?
-- ============================================================

WITH merchant_rates AS (
    SELECT 
        mr.merchant_id, 
        SUM(mr.chargebacks) AS TChBk, 
        SUM(mr.fraud_cases) AS TFrCs, 
        SUM(mt.transaction_count) AS TTrans, 
        SUM(mr.chargebacks) / SUM(mt.transaction_count) AS ChargeBkRate, 
        SUM(mr.fraud_cases) / SUM(mt.transaction_count) AS FraudRate
    FROM merchant_risk AS mr
    JOIN monthly_transactions AS mt
        ON mr.merchant_id = mt.merchant_id
        AND mr.month = mt.month
    GROUP BY mr.merchant_id
)
SELECT
    merchant_id,
    TChBk,
    TFrCs,
    TTrans,
    ChargeBkRate,
    FraudRate
FROM merchant_rates
WHERE ChargeBkRate >= 0.0139
   OR FraudRate >= 0.0064
ORDER BY ChargeBkRate DESC, FraudRate DESC;


-- Finding:
-- 33 merchants exceeded at least one of the portfolio's P95
-- thresholds: a chargeback rate of 1.39% or a fraud rate of 0.64%.
-- Several merchants showed elevated levels on both indicators,
-- including M0257, M0424, M0407, and M0200.
-- These merchants represent the highest chargeback/fraud activity
-- relative to the rest of the portfolio and are candidates for
-- further investigation.

-- ============================================================
-- 6A. ADVERSE MEDIA AND RISK
-- Do merchants with an adverse-media flag have higher
-- average risk scores?
-- ============================================================

SELECT
    ws.adverse_media_flag,
    COUNT(DISTINCT ws.merchant_id) AS TMerchants,
    AVG(mr.risk_score) AS AvgRisk
FROM website_signals AS ws
JOIN merchant_risk AS mr
    ON ws.merchant_id = mr.merchant_id
GROUP BY ws.adverse_media_flag
ORDER BY AvgRisk DESC;

-- Finding:
-- 23 merchants have an adverse-media flag and their average risk
-- score is 29.42, compared with 20.74 for the 577 merchants
-- without the flag.
-- This indicates an association between the adverse-media flag
-- and higher average risk scores in this portfolio.
-- The result shows an association, not causation.

-- ============================================================
-- 6B. WEBSITE RISK SCORE AND OVERALL MERCHANT RISK
-- Are higher website-risk scores associated with higher
-- overall merchant risk scores?
-- ============================================================

WITH merchant_metrics AS (
    SELECT
        merchant_id,
        AVG(risk_score) AS AvgRisk
    FROM merchant_risk
    GROUP BY merchant_id
),
correlation_values AS (
    SELECT
        COUNT(*) AS n,
        SUM(ws.website_risk_score) AS sum_x,
        SUM(mm.AvgRisk) AS sum_y,
        SUM(ws.website_risk_score * mm.AvgRisk) AS sum_xy,
        SUM(ws.website_risk_score * ws.website_risk_score) AS sum_x2,
        SUM(mm.AvgRisk * mm.AvgRisk) AS sum_y2
    FROM website_signals AS ws
    JOIN merchant_metrics AS mm
        ON ws.merchant_id = mm.merchant_id
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
-- The correlation between website-risk score and average merchant
-- risk score is approximately 0.235, indicating a weak positive
-- linear association in this portfolio.
-- Higher website-risk scores tend to occur alongside higher overall
-- merchant risk scores, but the relationship is not strong enough
-- for website risk to be considered a standalone indicator.

-- ============================================================
-- 7. RISK CONCENTRATION BY PAYFAC
-- Where is risk concentrated across PayFac partners?
-- ============================================================

USE merchant_risk_intelligence;

SELECT
    m.payfac_id,
    COUNT(DISTINCT m.merchant_id) AS TMerchants,
    AVG(mr.risk_score) AS AvgRisk
FROM merchants AS m
JOIN merchant_risk AS mr
    ON m.merchant_id = mr.merchant_id
GROUP BY m.payfac_id
ORDER BY AvgRisk DESC;

-- Finding:
-- PF10 has the highest average risk score (22.68) across its
-- 28 merchants, while PF09 has the lowest average risk score
-- (19.68) across its 38 merchants.
-- PF10's higher average risk should be considered alongside
-- its smaller merchant portfolio.

-- ============================================================
-- 8. MULTI-SIGNAL MERCHANT SCREENING
-- Which merchants show multiple risk indicators and may 
-- warrant further investigation?
-- ============================================================

WITH merchant_risk_metrics AS (
    SELECT
        merchant_id,
        AVG(risk_score) AS AvgRisk
    FROM merchant_risk
    GROUP BY merchant_id
),

repeated_increases AS (
    SELECT
        merchant_id,
        COUNT(*) AS IncreaseMonths
    FROM (
        SELECT
            merchant_id,
            risk_score - LAG(risk_score) OVER (
                PARTITION BY merchant_id
                ORDER BY month
            ) AS RiskChange
        FROM merchant_risk
    ) AS monthly_changes
    WHERE RiskChange > 0
    GROUP BY merchant_id
),

sudden_deterioration AS (
    SELECT
        merchant_id
    FROM (
        SELECT
            merchant_id,
            risk_score - LAG(risk_score) OVER (
                PARTITION BY merchant_id
                ORDER BY month
            ) AS RiskChange
        FROM merchant_risk
    ) AS monthly_changes
    WHERE RiskChange >= 15
    GROUP BY merchant_id
),

merchant_rates AS (
    SELECT
        mr.merchant_id,
        SUM(mr.chargebacks) / SUM(mt.transaction_count) AS ChargebackRate,
        SUM(mr.fraud_cases) / SUM(mt.transaction_count) AS FraudRate
    FROM merchant_risk AS mr
    JOIN monthly_transactions AS mt
        ON mr.merchant_id = mt.merchant_id
        AND mr.month = mt.month
    GROUP BY mr.merchant_id
)

SELECT
    m.merchant_id,
    m.industry,
    m.payfac_id,

    CASE
        WHEN rmm.AvgRisk >= 22.6667 THEN 1
        ELSE 0
    END AS Elevated_Avg_Risk,

    CASE
        WHEN ri.IncreaseMonths > 6 THEN 1
        ELSE 0
    END AS Repeated_Risk_Increases,

    CASE
        WHEN sd.merchant_id IS NOT NULL THEN 1
        ELSE 0
    END AS Sudden_Deterioration,

    CASE
        WHEN mrates.ChargebackRate >= 0.0139
          OR mrates.FraudRate >= 0.0064
        THEN 1
        ELSE 0
    END AS High_Chargeback_Fraud,

    CASE
        WHEN ws.adverse_media_flag = 1 THEN 1
        ELSE 0
    END AS Adverse_Media,

    (
        CASE WHEN rmm.AvgRisk >= 22.6667 THEN 1 ELSE 0 END +
        CASE WHEN ri.IncreaseMonths > 6 THEN 1 ELSE 0 END +
        CASE WHEN sd.merchant_id IS NOT NULL THEN 1 ELSE 0 END +
        CASE
            WHEN mrates.ChargebackRate >= 0.0139
              OR mrates.FraudRate >= 0.0064
            THEN 1
            ELSE 0
        END +
        CASE WHEN ws.adverse_media_flag = 1 THEN 1 ELSE 0 END
    ) AS Total_Risk_Signals

FROM merchants AS m
JOIN merchant_risk_metrics AS rmm
    ON m.merchant_id = rmm.merchant_id
LEFT JOIN repeated_increases AS ri
    ON m.merchant_id = ri.merchant_id
LEFT JOIN sudden_deterioration AS sd
    ON m.merchant_id = sd.merchant_id
JOIN merchant_rates AS mrates
    ON m.merchant_id = mrates.merchant_id
JOIN website_signals AS ws
    ON m.merchant_id = ws.merchant_id

ORDER BY Total_Risk_Signals DESC, rmm.AvgRisk DESC;

-- Finding:
-- 16 merchants triggered 3 or more of the 5 defined risk
-- screening signals, making them the clearest candidates for
-- further investigation.
-- 3 merchants triggered 4 signals: M0070, M0281, and M0055.
-- These results identify investigation priorities based on
-- overlapping risk indicators and should not be interpreted
-- as proof that the merchants are problematic.

-- ============================================================
-- END CONCLUSION
-- ============================================================
-- The portfolio is predominantly low risk based on average
-- annual risk scores, but a smaller group of merchants shows
-- persistently elevated or deteriorating risk.
-- Risk analysis identified merchants with repeated risk increases,
-- sudden deterioration events, elevated chargeback/fraud rates,
-- and associations between certain external risk indicators
-- and higher average risk scores.
-- A multi-signal screening identified 16 merchants with 3 or
-- more defined risk signals, including M0070, M0281, and M0055,
-- which each triggered 4 signals.
-- These results provide a screening basis for further merchant
-- investigation and monitoring rather than proof of problematic
-- activity.