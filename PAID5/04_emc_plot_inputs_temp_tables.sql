/*
Purpose:
  Build all aggregated inputs needed for:
  - PAID5/02_visualize_agg_PRO.R
  - PAID5/03_visualize_clinical.R

Site:
  EMC (clinical values are read from MEASUREMENT)

Output temp tables (same shape as *_agg.csv files):
  #agg_5_1, #agg_5_2, #agg_5_3, #agg_5_4, #agg_5_5
  #agg_hba1c_value, #agg_total_cholesterol_value, #agg_triglycerides_value,
  #agg_systolic_bp_value, #agg_diastolic_bp_value

Assumptions:
  - SQL Server syntax (temp tables with #)
  - Replace [YOUR_CDM_SCHEMA] with your schema name
  - This script mirrors the current R logic, including "closest_overall" matching
    and a minimum patient threshold of 5.
*/

SET NOCOUNT ON;

/* ============================================================================
   0) Parameters
============================================================================ */
DECLARE @min_patient_threshold INT = 5;

/* ============================================================================
   1) Cleanup
============================================================================ */
DROP TABLE IF EXISTS #question_map;
DROP TABLE IF EXISTS #answer_map;
DROP TABLE IF EXISTS #clinical_concepts_emc;
DROP TABLE IF EXISTS #diabetes_descendants;
DROP TABLE IF EXISTS #diabetes_concepts;
DROP TABLE IF EXISTS #pro_raw;
DROP TABLE IF EXISTS #clinical_raw;
DROP TABLE IF EXISTS #clinical_best_match;
DROP TABLE IF EXISTS #pro_enriched;
DROP TABLE IF EXISTS #paid5_1_mix;
DROP TABLE IF EXISTS #paid5_2_mix;
DROP TABLE IF EXISTS #paid5_3_mix;
DROP TABLE IF EXISTS #paid5_4_mix;
DROP TABLE IF EXISTS #paid5_5_mix;
DROP TABLE IF EXISTS #agg_5_1;
DROP TABLE IF EXISTS #agg_5_2;
DROP TABLE IF EXISTS #agg_5_3;
DROP TABLE IF EXISTS #agg_5_4;
DROP TABLE IF EXISTS #agg_5_5;
DROP TABLE IF EXISTS #clinical_distinct_visits;
DROP TABLE IF EXISTS #agg_hba1c_value;
DROP TABLE IF EXISTS #agg_total_cholesterol_value;
DROP TABLE IF EXISTS #agg_triglycerides_value;
DROP TABLE IF EXISTS #agg_systolic_bp_value;
DROP TABLE IF EXISTS #agg_diastolic_bp_value;

/* ============================================================================
   2) Concept maps (from PAID5/01_conversion_tables.R)
============================================================================ */
CREATE TABLE #question_map (
  question_concept_id BIGINT NOT NULL PRIMARY KEY,
  question_number     VARCHAR(10) NOT NULL
);

INSERT INTO #question_map (question_concept_id, question_number)
VALUES
  (40768166, '5_1'),
  (1761895,  '5_2'),
  (1989000,  '5_3'),
  (42690315, '5_4'),
  (4112552,  '5_5');

CREATE TABLE #answer_map (
  answer_concept_id BIGINT NOT NULL PRIMARY KEY,
  answer_value      FLOAT  NOT NULL
);

INSERT INTO #answer_map (answer_concept_id, answer_value)
VALUES
  (21499256, 0),
  (1177370,  1),
  (45877983, 2),
  (1177250,  3),
  (45883536, 4);

CREATE TABLE #clinical_concepts_emc (
  measurement_concept_id BIGINT NOT NULL PRIMARY KEY
);

INSERT INTO #clinical_concepts_emc (measurement_concept_id)
VALUES
  (3004410), -- HbA1c
  (3019900), -- Total cholesterol
  (3001308), -- LDL cholesterol (not plotted, kept for parity)
  (3023602), -- HDL cholesterol (not plotted, kept for parity)
  (3025839), -- Triglycerides
  (3004249), -- Systolic BP
  (3012888); -- Diastolic BP

/* ============================================================================
   3) Diabetes concept set (same logic as R script; currently not filtering out
      non-diabetes because the original join is LEFT JOIN without filter)
============================================================================ */
SELECT DISTINCT ca.descendant_concept_id AS concept_id
INTO #diabetes_descendants
FROM [YOUR_CDM_SCHEMA].concept_ancestor ca
JOIN [YOUR_CDM_SCHEMA].concept c
  ON ca.descendant_concept_id = c.concept_id
WHERE ca.ancestor_concept_id IN (201826, 4193704, 4008576, 201254);

SELECT concept_id
INTO #diabetes_concepts
FROM #diabetes_descendants
UNION
SELECT 201820
UNION
SELECT 37018196;

/* ============================================================================
   4) Pull PRO responses + EMC clinical measurements
============================================================================ */
SELECT
  r.person_id,
  r.observation_concept_id                  AS question_concept_id,
  r.value_as_concept_id                     AS answer_concept_id,
  CAST(r.observation_date AS DATE)          AS questionnaire_date
INTO #pro_raw
FROM [YOUR_CDM_SCHEMA].observation r
WHERE r.observation_concept_id IN (40768166, 1761895, 1989000, 42690315, 4112552);

SELECT
  m.person_id,
  m.measurement_concept_id,
  m.value_as_number,
  CAST(m.measurement_date AS DATE)          AS measurement_date
INTO #clinical_raw
FROM [YOUR_CDM_SCHEMA].measurement m
WHERE m.measurement_concept_id IN (3004410, 3019900, 3001308, 3023602, 3025839, 3004249, 3012888);

/* ============================================================================
   5) Match closest clinical value to each PRO row (closest_overall strategy)
      Equivalent to:
      - left_join by person_id
      - date_diff = abs(questionnaire_date - measurement_date)
      - for each (person, question, questionnaire_date, measurement_concept_id):
        keep smallest date_diff
============================================================================ */
WITH ranked_matches AS (
  SELECT
    p.person_id,
    p.question_concept_id,
    p.questionnaire_date,
    c.measurement_concept_id,
    c.value_as_number,
    c.measurement_date,
    ABS(DATEDIFF(DAY, p.questionnaire_date, c.measurement_date)) AS date_diff,
    ROW_NUMBER() OVER (
      PARTITION BY
        p.person_id,
        p.question_concept_id,
        p.questionnaire_date,
        c.measurement_concept_id
      ORDER BY
        ABS(DATEDIFF(DAY, p.questionnaire_date, c.measurement_date)) ASC,
        c.measurement_date ASC
    ) AS rn
  FROM #pro_raw p
  JOIN #clinical_raw c
    ON p.person_id = c.person_id
)
SELECT
  person_id,
  question_concept_id,
  questionnaire_date,
  measurement_concept_id,
  value_as_number
INTO #clinical_best_match
FROM ranked_matches
WHERE rn = 1;

/* ============================================================================
   6) Build mixed PRO table (equivalent to *_mix.csv shape)
============================================================================ */
SELECT
  p.person_id,
  p.question_concept_id,
  qm.question_number,
  p.answer_concept_id,
  am.answer_value,
  p.questionnaire_date,
  CAST(ROW_NUMBER() OVER (
    PARTITION BY p.person_id, p.question_concept_id
    ORDER BY p.questionnaire_date ASC
  ) AS INT)                                  AS answer_time,
  MAX(CASE WHEN cbm.measurement_concept_id = 3004410 THEN cbm.value_as_number END) AS hba1c_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3019900 THEN cbm.value_as_number END) AS total_cholesterol_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3001308 THEN cbm.value_as_number END) AS ldl_cholesterol_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3023602 THEN cbm.value_as_number END) AS hdl_cholesterol_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3025839 THEN cbm.value_as_number END) AS triglycerides_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3004249 THEN cbm.value_as_number END) AS systolic_bp_value,
  MAX(CASE WHEN cbm.measurement_concept_id = 3012888 THEN cbm.value_as_number END) AS diastolic_bp_value
INTO #pro_enriched
FROM #pro_raw p
LEFT JOIN #question_map qm
  ON p.question_concept_id = qm.question_concept_id
LEFT JOIN #answer_map am
  ON p.answer_concept_id = am.answer_concept_id
LEFT JOIN #clinical_best_match cbm
  ON p.person_id = cbm.person_id
 AND p.question_concept_id = cbm.question_concept_id
 AND p.questionnaire_date = cbm.questionnaire_date
GROUP BY
  p.person_id,
  p.question_concept_id,
  qm.question_number,
  p.answer_concept_id,
  am.answer_value,
  p.questionnaire_date;

/* Question-specific mixed tables (same intent as 5_1_mix.csv ... 5_5_mix.csv) */
SELECT * INTO #paid5_1_mix FROM #pro_enriched WHERE question_number = '5_1';
SELECT * INTO #paid5_2_mix FROM #pro_enriched WHERE question_number = '5_2';
SELECT * INTO #paid5_3_mix FROM #pro_enriched WHERE question_number = '5_3';
SELECT * INTO #paid5_4_mix FROM #pro_enriched WHERE question_number = '5_4';
SELECT * INTO #paid5_5_mix FROM #pro_enriched WHERE question_number = '5_5';

/* ============================================================================
   7) Aggregations for 02_visualize_agg_PRO.R
      Output columns: answer_time, mean_value, sd_value, patient_count
============================================================================ */
SELECT
  answer_time,
  AVG(answer_value) AS mean_value,
  COALESCE(STDEV(answer_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_5_1
FROM #paid5_1_mix
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(answer_value) AS mean_value,
  COALESCE(STDEV(answer_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_5_2
FROM #paid5_2_mix
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(answer_value) AS mean_value,
  COALESCE(STDEV(answer_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_5_3
FROM #paid5_3_mix
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(answer_value) AS mean_value,
  COALESCE(STDEV(answer_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_5_4
FROM #paid5_4_mix
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(answer_value) AS mean_value,
  COALESCE(STDEV(answer_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_5_5
FROM #paid5_5_mix
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

/* ============================================================================
   8) Aggregations for 03_visualize_clinical.R
      R script uses only 5_1_mix as source for clinical trend aggregation.
============================================================================ */
SELECT DISTINCT
  person_id,
  answer_time,
  hba1c_value,
  total_cholesterol_value,
  triglycerides_value,
  systolic_bp_value,
  diastolic_bp_value
INTO #clinical_distinct_visits
FROM #paid5_1_mix;

SELECT
  answer_time,
  AVG(hba1c_value) AS mean_value,
  COALESCE(STDEV(hba1c_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_hba1c_value
FROM #clinical_distinct_visits
WHERE hba1c_value IS NOT NULL
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(total_cholesterol_value) AS mean_value,
  COALESCE(STDEV(total_cholesterol_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_total_cholesterol_value
FROM #clinical_distinct_visits
WHERE total_cholesterol_value IS NOT NULL
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(triglycerides_value) AS mean_value,
  COALESCE(STDEV(triglycerides_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_triglycerides_value
FROM #clinical_distinct_visits
WHERE triglycerides_value IS NOT NULL
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(systolic_bp_value) AS mean_value,
  COALESCE(STDEV(systolic_bp_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_systolic_bp_value
FROM #clinical_distinct_visits
WHERE systolic_bp_value IS NOT NULL
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

SELECT
  answer_time,
  AVG(diastolic_bp_value) AS mean_value,
  COALESCE(STDEV(diastolic_bp_value), 0) AS sd_value,
  COUNT(*) AS patient_count
INTO #agg_diastolic_bp_value
FROM #clinical_distinct_visits
WHERE diastolic_bp_value IS NOT NULL
GROUP BY answer_time
HAVING COUNT(*) >= @min_patient_threshold;

/* ============================================================================
   9) Final result sets to export/use for plotting
============================================================================ */
SELECT * FROM #agg_5_1 ORDER BY answer_time;
SELECT * FROM #agg_5_2 ORDER BY answer_time;
SELECT * FROM #agg_5_3 ORDER BY answer_time;
SELECT * FROM #agg_5_4 ORDER BY answer_time;
SELECT * FROM #agg_5_5 ORDER BY answer_time;

SELECT * FROM #agg_hba1c_value ORDER BY answer_time;
SELECT * FROM #agg_total_cholesterol_value ORDER BY answer_time;
SELECT * FROM #agg_triglycerides_value ORDER BY answer_time;
SELECT * FROM #agg_systolic_bp_value ORDER BY answer_time;
SELECT * FROM #agg_diastolic_bp_value ORDER BY answer_time;

