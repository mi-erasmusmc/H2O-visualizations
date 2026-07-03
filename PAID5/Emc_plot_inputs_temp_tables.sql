/*
Purpose:
  Build all aggregated inputs needed for:
  - PAID5/02_visualize_agg_PRO.R
  - PAID5/03_visualize_clinical.R

Site:
  EMC (clinical values are read from MEASUREMENT)

Dialect:
  PostgreSQL (temp tables)

Output temp tables (same shape as *_agg.csv files):
  tmp_agg_5_1, tmp_agg_5_2, tmp_agg_5_3, tmp_agg_5_4, tmp_agg_5_5
  tmp_agg_hba1c_value, tmp_agg_total_cholesterol_value, tmp_agg_triglycerides_value,
  tmp_agg_systolic_bp_value, tmp_agg_diastolic_bp_value

Replace:
  YOUR_CDM_SCHEMA with your schema name (without square brackets).
*/

/* ============================================================================
   0) Parameters
============================================================================ */
DROP TABLE IF EXISTS tmp_params;
CREATE TEMP TABLE tmp_params AS
SELECT 5::int AS min_patient_threshold;

/* ============================================================================
   1) Cleanup
============================================================================ */
DROP TABLE IF EXISTS tmp_question_map;
DROP TABLE IF EXISTS tmp_answer_map;
DROP TABLE IF EXISTS tmp_clinical_concepts_emc;
DROP TABLE IF EXISTS tmp_diabetes_descendants;
DROP TABLE IF EXISTS tmp_diabetes_concepts;
DROP TABLE IF EXISTS tmp_pro_raw;
DROP TABLE IF EXISTS tmp_clinical_raw;
DROP TABLE IF EXISTS tmp_clinical_best_match;
DROP TABLE IF EXISTS tmp_pro_enriched;
DROP TABLE IF EXISTS tmp_paid5_1_mix;
DROP TABLE IF EXISTS tmp_paid5_2_mix;
DROP TABLE IF EXISTS tmp_paid5_3_mix;
DROP TABLE IF EXISTS tmp_paid5_4_mix;
DROP TABLE IF EXISTS tmp_paid5_5_mix;
DROP TABLE IF EXISTS tmp_agg_5_1;
DROP TABLE IF EXISTS tmp_agg_5_2;
DROP TABLE IF EXISTS tmp_agg_5_3;
DROP TABLE IF EXISTS tmp_agg_5_4;
DROP TABLE IF EXISTS tmp_agg_5_5;
DROP TABLE IF EXISTS tmp_clinical_distinct_visits;
DROP TABLE IF EXISTS tmp_agg_hba1c_value;
DROP TABLE IF EXISTS tmp_agg_total_cholesterol_value;
DROP TABLE IF EXISTS tmp_agg_triglycerides_value;
DROP TABLE IF EXISTS tmp_agg_systolic_bp_value;
DROP TABLE IF EXISTS tmp_agg_diastolic_bp_value;

/* ============================================================================
   2) Concept maps (from PAID5/01_conversion_tables.R)
============================================================================ */
CREATE TEMP TABLE tmp_question_map (
  question_concept_id bigint PRIMARY KEY,
  question_number     varchar(10) NOT NULL
);

INSERT INTO tmp_question_map (question_concept_id, question_number)
VALUES
  (40768166, '5_1'),
  (1761895,  '5_2'),
  (1989000,  '5_3'),
  (42690315, '5_4'),
  (4112552,  '5_5');

CREATE TEMP TABLE tmp_answer_map (
  answer_concept_id bigint PRIMARY KEY,
  answer_value      double precision NOT NULL
);

INSERT INTO tmp_answer_map (answer_concept_id, answer_value)
VALUES
  (21499256, 0),
  (1177370,  1),
  (45877983, 2),
  (1177250,  3),
  (45883536, 4);

CREATE TEMP TABLE tmp_clinical_concepts_emc (
  measurement_concept_id bigint PRIMARY KEY
);

INSERT INTO tmp_clinical_concepts_emc (measurement_concept_id)
VALUES
  (3004410), -- HbA1c
  (3019900), -- Total cholesterol
  (3001308), -- LDL cholesterol (not plotted, kept for parity)
  (3023602), -- HDL cholesterol (not plotted, kept for parity)
  (3025839), -- Triglycerides
  (3004249), -- Systolic BP
  (3012888); -- Diastolic BP

/* ============================================================================
   3) Diabetes concept set (same logic as R script; not used to filter output)
============================================================================ */
CREATE TEMP TABLE tmp_diabetes_descendants AS
SELECT DISTINCT ca.descendant_concept_id AS concept_id
FROM YOUR_CDM_SCHEMA.concept_ancestor ca
JOIN YOUR_CDM_SCHEMA.concept c
  ON ca.descendant_concept_id = c.concept_id
WHERE ca.ancestor_concept_id IN (201826, 4193704, 4008576, 201254);

CREATE TEMP TABLE tmp_diabetes_concepts AS
SELECT concept_id FROM tmp_diabetes_descendants
UNION
SELECT 201820
UNION
SELECT 37018196;

/* ============================================================================
   4) Pull PRO responses + EMC clinical measurements
============================================================================ */
CREATE TEMP TABLE tmp_pro_raw AS
SELECT
  r.person_id,
  r.observation_concept_id::bigint AS question_concept_id,
  r.value_as_concept_id::bigint    AS answer_concept_id,
  r.observation_date::date         AS questionnaire_date
FROM YOUR_CDM_SCHEMA.observation r
WHERE r.observation_concept_id IN (40768166, 1761895, 1989000, 42690315, 4112552);

CREATE TEMP TABLE tmp_clinical_raw AS
SELECT
  m.person_id,
  m.measurement_concept_id::bigint AS measurement_concept_id,
  m.value_as_number,
  m.measurement_date::date          AS measurement_date
FROM YOUR_CDM_SCHEMA.measurement m
WHERE m.measurement_concept_id IN (3004410, 3019900, 3001308, 3023602, 3025839, 3004249, 3012888);

/* ============================================================================
   5) Match closest clinical value to each PRO row (closest_overall strategy)
============================================================================ */
CREATE TEMP TABLE tmp_clinical_best_match AS
WITH ranked_matches AS (
  SELECT
    p.person_id,
    p.question_concept_id,
    p.questionnaire_date,
    c.measurement_concept_id,
    c.value_as_number,
    c.measurement_date,
    abs(p.questionnaire_date - c.measurement_date) AS date_diff,
    row_number() OVER (
      PARTITION BY
        p.person_id,
        p.question_concept_id,
        p.questionnaire_date,
        c.measurement_concept_id
      ORDER BY
        abs(p.questionnaire_date - c.measurement_date) ASC,
        c.measurement_date ASC
    ) AS rn
  FROM tmp_pro_raw p
  JOIN tmp_clinical_raw c
    ON p.person_id = c.person_id
)
SELECT
  person_id,
  question_concept_id,
  questionnaire_date,
  measurement_concept_id,
  value_as_number
FROM ranked_matches
WHERE rn = 1;

/* ============================================================================
   6) Build mixed PRO table (equivalent to *_mix.csv shape)
============================================================================ */
CREATE TEMP TABLE tmp_pro_enriched AS
SELECT
  p.person_id,
  p.question_concept_id,
  qm.question_number,
  p.answer_concept_id,
  am.answer_value,
  p.questionnaire_date,
  row_number() OVER (
    PARTITION BY p.person_id, p.question_concept_id
    ORDER BY p.questionnaire_date ASC
  )::int AS answer_time,
  max(CASE WHEN cbm.measurement_concept_id = 3004410 THEN cbm.value_as_number END) AS hba1c_value,
  max(CASE WHEN cbm.measurement_concept_id = 3019900 THEN cbm.value_as_number END) AS total_cholesterol_value,
  max(CASE WHEN cbm.measurement_concept_id = 3001308 THEN cbm.value_as_number END) AS ldl_cholesterol_value,
  max(CASE WHEN cbm.measurement_concept_id = 3023602 THEN cbm.value_as_number END) AS hdl_cholesterol_value,
  max(CASE WHEN cbm.measurement_concept_id = 3025839 THEN cbm.value_as_number END) AS triglycerides_value,
  max(CASE WHEN cbm.measurement_concept_id = 3004249 THEN cbm.value_as_number END) AS systolic_bp_value,
  max(CASE WHEN cbm.measurement_concept_id = 3012888 THEN cbm.value_as_number END) AS diastolic_bp_value
FROM tmp_pro_raw p
LEFT JOIN tmp_question_map qm
  ON p.question_concept_id = qm.question_concept_id
LEFT JOIN tmp_answer_map am
  ON p.answer_concept_id = am.answer_concept_id
LEFT JOIN tmp_clinical_best_match cbm
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

CREATE TEMP TABLE tmp_paid5_1_mix AS SELECT * FROM tmp_pro_enriched WHERE question_number = '5_1';
CREATE TEMP TABLE tmp_paid5_2_mix AS SELECT * FROM tmp_pro_enriched WHERE question_number = '5_2';
CREATE TEMP TABLE tmp_paid5_3_mix AS SELECT * FROM tmp_pro_enriched WHERE question_number = '5_3';
CREATE TEMP TABLE tmp_paid5_4_mix AS SELECT * FROM tmp_pro_enriched WHERE question_number = '5_4';
CREATE TEMP TABLE tmp_paid5_5_mix AS SELECT * FROM tmp_pro_enriched WHERE question_number = '5_5';

/* ============================================================================
   7) Aggregations for 02_visualize_agg_PRO.R
============================================================================ */
CREATE TEMP TABLE tmp_agg_5_1 AS
SELECT
  answer_time,
  avg(answer_value)                 AS mean_value,
  coalesce(stddev_samp(answer_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_paid5_1_mix
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_5_2 AS
SELECT
  answer_time,
  avg(answer_value)                 AS mean_value,
  coalesce(stddev_samp(answer_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_paid5_2_mix
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_5_3 AS
SELECT
  answer_time,
  avg(answer_value)                 AS mean_value,
  coalesce(stddev_samp(answer_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_paid5_3_mix
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_5_4 AS
SELECT
  answer_time,
  avg(answer_value)                 AS mean_value,
  coalesce(stddev_samp(answer_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_paid5_4_mix
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_5_5 AS
SELECT
  answer_time,
  avg(answer_value)                 AS mean_value,
  coalesce(stddev_samp(answer_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_paid5_5_mix
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

/* ============================================================================
   8) Aggregations for 03_visualize_clinical.R
============================================================================ */
CREATE TEMP TABLE tmp_clinical_distinct_visits AS
SELECT DISTINCT
  person_id,
  answer_time,
  hba1c_value,
  total_cholesterol_value,
  triglycerides_value,
  systolic_bp_value,
  diastolic_bp_value
FROM tmp_paid5_1_mix;

CREATE TEMP TABLE tmp_agg_hba1c_value AS
SELECT
  answer_time,
  avg(hba1c_value)                  AS mean_value,
  coalesce(stddev_samp(hba1c_value), 0) AS sd_value,
  count(*)                          AS patient_count
FROM tmp_clinical_distinct_visits
WHERE hba1c_value IS NOT NULL
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_total_cholesterol_value AS
SELECT
  answer_time,
  avg(total_cholesterol_value)                 AS mean_value,
  coalesce(stddev_samp(total_cholesterol_value), 0) AS sd_value,
  count(*)                                     AS patient_count
FROM tmp_clinical_distinct_visits
WHERE total_cholesterol_value IS NOT NULL
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_triglycerides_value AS
SELECT
  answer_time,
  avg(triglycerides_value)                     AS mean_value,
  coalesce(stddev_samp(triglycerides_value), 0) AS sd_value,
  count(*)                                     AS patient_count
FROM tmp_clinical_distinct_visits
WHERE triglycerides_value IS NOT NULL
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_systolic_bp_value AS
SELECT
  answer_time,
  avg(systolic_bp_value)                     AS mean_value,
  coalesce(stddev_samp(systolic_bp_value), 0) AS sd_value,
  count(*)                                   AS patient_count
FROM tmp_clinical_distinct_visits
WHERE systolic_bp_value IS NOT NULL
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

CREATE TEMP TABLE tmp_agg_diastolic_bp_value AS
SELECT
  answer_time,
  avg(diastolic_bp_value)                     AS mean_value,
  coalesce(stddev_samp(diastolic_bp_value), 0) AS sd_value,
  count(*)                                    AS patient_count
FROM tmp_clinical_distinct_visits
WHERE diastolic_bp_value IS NOT NULL
GROUP BY answer_time
HAVING count(*) >= (SELECT min_patient_threshold FROM tmp_params);

/* ============================================================================
   9) Final result sets to export/use for plotting
============================================================================ */
SELECT * FROM tmp_agg_5_1 ORDER BY answer_time;
SELECT * FROM tmp_agg_5_2 ORDER BY answer_time;
SELECT * FROM tmp_agg_5_3 ORDER BY answer_time;
SELECT * FROM tmp_agg_5_4 ORDER BY answer_time;
SELECT * FROM tmp_agg_5_5 ORDER BY answer_time;

SELECT * FROM tmp_agg_hba1c_value ORDER BY answer_time;
SELECT * FROM tmp_agg_total_cholesterol_value ORDER BY answer_time;
SELECT * FROM tmp_agg_triglycerides_value ORDER BY answer_time;
SELECT * FROM tmp_agg_systolic_bp_value ORDER BY answer_time;
SELECT * FROM tmp_agg_diastolic_bp_value ORDER BY answer_time;

