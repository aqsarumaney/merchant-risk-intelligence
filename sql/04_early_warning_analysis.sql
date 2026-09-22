-- ============================================================
-- 1. RECENT SUDDEN RISK DETERIORATION
-- Which merchants experienced significant risk increases
-- during the most recent four months?
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
  AND month >= '2024-09'
ORDER BY Risk_Change DESC;

-- Finding:
-- 7 sudden risk deterioration events were identified during
-- the most recent four months using a screening threshold of
-- a +15 or greater month-to-month increase.
-- The largest increase was M0596 (+17) in December, followed
-- by M0006 (+16), M0141 (+16), and M0591 (+16).
-- M0141 was also identified as a persistently elevated-risk
-- merchant in File 3, while the other merchants may represent
-- more recent deterioration requiring monitoring.

-- ============================================================
-- 2. RECENT REPEATED RISK DETERIORATION
-- Which merchants have recent risk deterioration that may
-- require monitoring?
-- ============================================================

WITH New AS (
    SELECT 
        merchant_id,
        risk_score,
        month,
        LAG(risk_score) OVER (
            PARTITION BY merchant_id 
            ORDER BY month ASC
        ) AS Prevmonth
    FROM merchant_risk
),
New2 AS (
    SELECT 
        merchant_id,
        month,
        risk_score - Prevmonth AS Risk_Change
    FROM New
)
SELECT 
    merchant_id,
    COUNT(*) AS Increase_Months
FROM New2
WHERE Risk_Change > 0
  AND month >= '2024-07'
GROUP BY merchant_id
HAVING Increase_Months >= 5
ORDER BY Increase_Months DESC;

-- Finding:
-- 13 merchants experienced risk increases in at least 5 of the
-- 6 recent month-to-month comparisons from July through December.
-- M0055 increased in all 6 comparisons, while 12 other merchants
-- increased in 5 of 6 comparisons.
-- These merchants show repeated recent upward movement in risk
-- and may warrant continued monitoring.

-- ============================================================
-- 3. RECENT MULTI-SIGNAL MONITORING
-- Which merchants show multiple recent warning signs and may
-- require monitoring?
-- ============================================================

WITH monthly_changes AS (
    SELECT
        merchant_id,
        month,
        risk_score,
        LAG(risk_score) OVER (
            PARTITION BY merchant_id
            ORDER BY month
        ) AS Prevmonth
    FROM merchant_risk
),

recent_signals AS (
    SELECT
        merchant_id,

        SUM(
            CASE
                WHEN Risk_Change > 0 THEN 1
                ELSE 0
            END
        ) AS Increase_Months,

        MAX(
            CASE
                WHEN Risk_Change >= 15 THEN 1
                ELSE 0
            END
        ) AS Sudden_Deterioration

    FROM (
        SELECT
            merchant_id,
            month,
            risk_score - Prevmonth AS Risk_Change
        FROM monthly_changes
    ) AS changes
    WHERE month >= '2024-07'
    GROUP BY merchant_id
)

SELECT
    merchant_id,
    Increase_Months,
    Sudden_Deterioration,
    (
        CASE WHEN Increase_Months >= 5 THEN 1 ELSE 0 END +
        Sudden_Deterioration
    ) AS Recent_Risk_Signals
FROM recent_signals
WHERE Increase_Months >= 5
   OR Sudden_Deterioration = 1
ORDER BY Recent_Risk_Signals DESC, Increase_Months DESC;

-- Finding:
-- 26 merchants showed at least one recent warning signal.
-- 2 merchants, M0055 and M0281, showed both repeated recent
-- risk increases and a sudden risk deterioration.
-- These two merchants are the clearest candidates for continued
-- monitoring based on the recent warning signals analyzed.


-- ============================================================
-- END CONCLUSION
-- ============================================================
-- 26 merchants showed at least one recent risk-deterioration signal.
-- Of these, M0055 and M0281 triggered both repeated recent
-- deterioration and sudden deterioration, making them the clearest
-- candidates for continued monitoring based on the signals analyzed.