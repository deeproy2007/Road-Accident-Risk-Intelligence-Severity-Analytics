# 🚦 Road Accident Risk Analytics

A SQL-based analytics project focused on identifying accident trends, geographic risk concentration, and high-severity factors across Indian states from 2018 to 2023.

---

## 📌 Project Overview

Road accidents are a critical public safety concern. This project applies structured SQL analytics to a road accident dataset to surface actionable insights for policymakers, traffic authorities, and researchers.

**Core objectives:**
- Detect year-over-year accident trends to evaluate policy effectiveness
- Model geographic risk concentration using cumulative state-level analysis
- Assess fatality ratios across states to identify high-lethality zones
- Profile high-risk conditions by combining state, time-of-day, and weather factors
- Enable repeatable, parameterized state-level reporting via stored procedures

---

## 📂 Repository Structure

```
road-accident-analytics/
│
├── road_accident.csv                # Raw dataset (1,565 records, 22 features)
├── road_accident_analysis.sql       # Core analytics queries and schema
└── README.md                        # Project documentation
```

---

## 📊 Dataset Description

| Property | Details |
|---|---|
| **Records** | 1,565 accident records |
| **Time Span** | 2018 – 2023 |
| **Geographic Coverage** | 32 Indian States |
| **Severity Classes** | Fatal, Serious, Minor |

### Features

| Column | Description |
|---|---|
| `State_Name` | State where the accident occurred |
| `Year`, `Month`, `Day_of_Week` | Temporal attributes |
| `Time_of_Day` | Time of accident (used for time bucketing) |
| `Accident_Severity` | Fatal / Serious / Minor |
| `Number_of_Vehicles_Involved` | Count of vehicles in the accident |
| `Vehicle_Type_Involved` | Type of vehicle(s) |
| `Number_of_Casualties` | Injured persons |
| `Number_of_Fatalities` | Deaths recorded |
| `Weather_Conditions` | Weather at the time of accident |
| `Road_Type`, `Road_Condition` | Infrastructure context |
| `Lighting_Conditions` | Daylight, night, artificial, etc. |
| `Traffic_Control_Presence` | Signal, sign, none, etc. |
| `Speed_Limit` | Posted speed limit at the location |
| `Driver_Age`, `Driver_Gender` | Driver demographics |
| `Driver_License_Status` | Licensed / Unlicensed |
| `Alcohol_Involvement` | Whether alcohol was a factor |
| `Age_group` | Age bracket of the driver |

---

## 🛠️ SQL Analytics Modules

### 1. Feature Engineering — `accident_base` View

A foundational view built on top of the raw table that standardizes two key dimensions used across all downstream queries:

- **Severity Score** — Maps textual severity to a numeric scale: `Fatal → 3`, `Serious → 2`, `Minor → 1`
- **Time Bucket** — Segments `Time_of_Day` into `Morning`, `Afternoon`, `Evening`, `Night`

```sql
CREATE VIEW accident_base AS
SELECT *,
  CASE Accident_Severity
    WHEN 'Fatal'   THEN 3
    WHEN 'Serious' THEN 2
    WHEN 'Minor'   THEN 1
  END AS severity_score,
  CASE
    WHEN HOUR(Time_of_Day) BETWEEN 6  AND 11 THEN 'Morning'
    WHEN HOUR(Time_of_Day) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN HOUR(Time_of_Day) BETWEEN 18 AND 21 THEN 'Evening'
    ELSE 'Night'
  END AS time_bucket
FROM road_accident;
```

---

### 2. Trend Analysis — Year-over-Year Growth

Calculates annual accident counts and YoY change using window functions to measure whether road safety policies are having a measurable impact.

**Key metric:** `yoy_growth_pct` — percentage change in accidents from the previous year.

---

### 3. Strategic Severity Trend — 3-Year Rolling Average

Smooths short-term fluctuations in average accident severity to reveal structural risk increases or improvements over time.

**Key metric:** `rolling_3yr_severity` — a 3-year window average of severity scores.

---

### 4. Risk Concentration — Pareto Analysis by State

Ranks states by accident volume and computes a cumulative percentage, enabling a Pareto-style identification of which states account for the majority of national accidents.

**Key metric:** `cumulative_pct` — identifies which states collectively contribute 80% of total accidents.

---

### 5. Lethality Assessment — Fatal Ratio by State

Evaluates the fatality ratio for each state to distinguish between states with high accident *volume* versus those with high accident *lethality* — two distinct risk profiles requiring different interventions.

**Key metric:** `fatal_ratio_pct = (fatal_count / total_accidents) × 100`

---

### 6. High-Risk Condition Modeling — State × Time × Weather

A multi-dimensional risk table combining state, time bucket, and weather conditions with average severity score to identify the most dangerous contextual combinations.

**Key metric:** `risk_score` — average severity score per combination, sorted descending.

---

### 7. Automation — Parameterized State Report (Stored Procedure)

A reusable stored procedure that generates a year-by-year accident summary and average severity for any given state, enabling repeatable regional reporting without rewriting queries.

```sql
CALL state_report('Maharashtra');
```

---

### 8. Optimization — Composite Index

A composite index on `(State_Name, Year)` is created to optimize the most common query patterns — state-level filtering and annual trend grouping — reducing full table scans on large datasets.

```sql
CREATE INDEX idx_state_year ON road_accident(State_Name, Year);
```

---

## 🚀 Getting Started

### Prerequisites

- MySQL 8.0+ (window functions and CTEs required)
- A MySQL client: MySQL Workbench, DBeaver, or CLI

### Setup

```sql
-- 1. Create your database
CREATE DATABASE road_accident_db;
USE road_accident_db;

-- 2. Import the dataset
--    Use MySQL Workbench's Table Data Import Wizard, or:
LOAD DATA INFILE '/path/to/road_accident.csv'
INTO TABLE road_accident
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Run the analysis script
SOURCE road_accident_analysis.sql;
```

---

## 💡 Key Analytical Questions Answered

| Question | Module |
|---|---|
| Are accidents increasing or decreasing year over year? | Trend Analysis |
| Is road risk severity worsening structurally? | Rolling Severity |
| Which states contribute most to national accident burden? | Risk Concentration |
| Which states are the most deadly per accident? | Lethality Assessment |
| What state-time-weather combos are highest risk? | Condition Modeling |
| How can I generate a repeatable state-level report? | Stored Procedure |

---

## 📈 Potential Extensions

- Connect to a BI tool (Power BI / Tableau) for dashboard visualizations
- Add a Python EDA layer using `pandas` and `seaborn` for visual profiling
- Incorporate population data to compute per-capita accident rates by state
- Build a machine learning model to predict accident severity from contextual features

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Please open an issue before submitting a pull request.

---

## 📄 License

This project is licensed under the MIT License. See `LICENSE` for details.
