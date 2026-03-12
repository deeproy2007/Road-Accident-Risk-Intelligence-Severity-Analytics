-- Road Accident Risk Analytics Project
-- Objective: Identify trend patterns, risk concentration, and high-severity factors
-- Scope: Trend analysis, geographic risk modeling, fatality assessment, automation
-- Feature Engineering: Standardizing severity and time segmentation for risk modeling
CREATE VIEW accident_base AS
SELECT *,
  CASE
    WHEN Accident_Severity = 'Fatal' THEN 3
    WHEN Accident_Severity = 'Serious' THEN 2
    WHEN Accident_Severity = 'Minor' THEN 1
    ELSE NULL
  END AS severity_score,

  CASE
    WHEN Time_of_Day IS NULL THEN 'Unknown'
    WHEN HOUR(Time_of_Day) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN HOUR(Time_of_Day) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN HOUR(Time_of_Day) BETWEEN 18 AND 21 THEN 'Evening'
    ELSE 'Night'
  END AS time_bucket
FROM road_accident;
-- Trend Analysis: Year-over-Year accident growth to evaluate policy effectiveness
WITH yearly AS (
  SELECT
    Year,
    COUNT(*) AS total_accidents
  FROM accident_base
  GROUP BY Year
)
SELECT
  Year,
  total_accidents,
  total_accidents - LAG(total_accidents) OVER (ORDER BY Year) AS yoy_change,
  ROUND(
    (total_accidents - LAG(total_accidents) OVER (ORDER BY Year))
    * 100.0 /
    LAG(total_accidents) OVER (ORDER BY Year), 2
  ) AS yoy_growth_pct
FROM yearly;
-- Strategic Severity Trend: 3-year rolling average to detect structural risk increase
WITH yearly_severity AS (
  SELECT
    Year,
    AVG(severity_score) AS avg_severity
  FROM accident_base
  GROUP BY Year
)
SELECT
  Year,
  ROUND(
    AVG(avg_severity) OVER (
      ORDER BY Year
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2
  ) AS rolling_3yr_severity
FROM yearly_severity;

-- Risk Concentration: Identify states contributing majority of total accidents
WITH state_stats AS (
  SELECT
    State_Name,
    COUNT(*) AS total_accidents
  FROM accident_base
  GROUP BY State_Name
),
ranked AS (
  SELECT *,
    SUM(total_accidents) OVER (ORDER BY total_accidents DESC) AS cumulative,
    SUM(total_accidents) OVER () AS grand_total
  FROM state_stats
)
SELECT
  State_Name,
  total_accidents,
  ROUND(cumulative * 100.0 / grand_total, 2) AS cumulative_pct
FROM ranked;  
-- Lethality Assessment: Evaluate fatality ratio across states
SELECT
  State_Name,
  SUM(CASE WHEN Accident_Severity = 'Fatal' THEN 1 ELSE 0 END) AS fatal_count,
  COUNT(*) AS total_accidents,
  ROUND(
    SUM(CASE WHEN Accident_Severity = 'Fatal' THEN 1 ELSE 0 END)
    * 100.0 / COUNT(*), 2
  ) AS fatal_ratio_pct
FROM accident_base
GROUP BY State_Name
ORDER BY fatal_ratio_pct DESC;
-- High-Risk Condition Modeling: State × Time × Weather severity analysis
SELECT
  State_Name,
  time_bucket,
  Weather_Conditions,
  COUNT(*) AS accidents,
  ROUND(AVG(severity_score),2) AS risk_score
FROM accident_base
GROUP BY State_Name, time_bucket, Weather_Conditions
ORDER BY risk_score DESC;

-- Automation: Parameterized state-level yearly accident reporting
DELIMITER $$

CREATE PROCEDURE state_report(IN input_state VARCHAR(100))
BEGIN
  SELECT
    Year,
    COUNT(*) AS accidents,
    ROUND(AVG(severity_score),2) AS avg_severity
  FROM accident_base
  WHERE State_Name = input_state
  GROUP BY Year;
END $$

DELIMITER ;
--  Optimization: Composite index to improve filtering and trend queries performance
CREATE INDEX idx_state_year
ON road_accident(State_Name, Year);

