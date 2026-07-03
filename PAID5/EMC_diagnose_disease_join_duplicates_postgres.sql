/*
Purpose:
  Diagnose why the PAID disease join creates duplicate/multiplied rows
  in one CDM instance but not another.

How to use:
  1) Replace cdm below.
  2) Run this script on CDM instance A.
  3) Save all result sets.
  4) Run the same script on CDM instance B and compare.

Dialect:
  PostgreSQL

Context:
  Mirrors logic in PAID5/01_collect_PRO_and_clinical.R:
  - response = observation rows for question concepts
  - disease  = DISTINCT(person_id, condition_concept_id) for diabetes concept set
  - join on person_id only
*/

/* ============================================================================
   0) Inputs and concept sets
============================================================================ */
DROP TABLE IF EXISTS tmp_diag_question_concepts;
DROP TABLE IF EXISTS tmp_diag_diabetes_descendants;
DROP TABLE IF EXISTS tmp_diag_diabetes_concepts;
DROP TABLE IF EXISTS tmp_diag_response;
DROP TABLE IF EXISTS tmp_diag_disease;
DROP TABLE IF EXISTS tmp_diag_joined;

CREATE TEMP TABLE tmp_diag_question_concepts (concept_id bigint PRIMARY KEY);
INSERT INTO tmp_diag_question_concepts (concept_id)
VALUES (40768166), (1761895), (1989000), (42690315), (4112552);

CREATE TEMP TABLE tmp_diag_diabetes_descendants AS
SELECT DISTINCT ca.descendant_concept_id AS concept_id
FROM cdm.concept_ancestor ca
JOIN cdm.concept c
  ON c.concept_id = ca.descendant_concept_id
WHERE ca.ancestor_concept_id IN (201826, 4193704, 4008576, 201254);

CREATE TEMP TABLE tmp_diag_diabetes_concepts AS
SELECT concept_id FROM tmp_diag_diabetes_descendants
UNION
SELECT 201820
UNION
SELECT 37018196;

/*
   1) Recreate R-side response and disease tables
============================================================================ */
CREATE TEMP TABLE tmp_diag_response AS
SELECT
  o.person_id,
  o.observation_concept_id AS question_concept_id,
  o.value_as_concept_id    AS answer_concept_id,
  o.observation_date       AS questionnaire_date
FROM cdm.observation o
WHERE o.observation_concept_id IN (SELECT concept_id FROM tmp_diag_question_concepts);

CREATE TEMP TABLE tmp_diag_disease AS
SELECT DISTINCT
  co.person_id,
  co.condition_concept_id
FROM cdm.condition_occurrence co
WHERE co.condition_concept_id IN (SELECT concept_id FROM tmp_diag_diabetes_concepts);

CREATE TEMP TABLE tmp_diag_joined AS
SELECT
  r.person_id,
  r.question_concept_id,
  r.answer_concept_id,
  r.questionnaire_date,
  d.condition_concept_id AS disease_concept_id
FROM tmp_diag_response r
LEFT JOIN tmp_diag_disease d
  ON d.person_id = r.person_id;

/*
   2) High-level row multiplication summary
============================================================================ */
SELECT
  'response_rows' AS metric,
  count(*)::bigint AS value
FROM tmp_diag_response
UNION ALL
SELECT
  'joined_rows' AS metric,
  count(*)::bigint AS value
FROM tmp_diag_joined
UNION ALL
SELECT
  'row_multiplier_joined_over_response' AS metric,
  round((SELECT count(*)::numeric FROM tmp_diag_joined) / nullif((SELECT count(*)::numeric FROM tmp_diag_response), 0), 4)::numeric AS value;

/*
   3) Is response already duplicated before any disease join?
      (Same key columns used in R before disease column matters)
============================================================================ */
SELECT
  person_id,
  question_concept_id,
  answer_concept_id,
  questionnaire_date,
  count(*) AS duplicate_count
FROM tmp_diag_response
GROUP BY
  person_id,
  question_concept_id,
  answer_concept_id,
  questionnaire_date
HAVING count(*) > 1
ORDER BY duplicate_count DESC, person_id
LIMIT 100;

/*
   4) Disease multiplicity by person (main cause of join expansion)
============================================================================ */
SELECT
  disease_rows_per_person,
  count(*) AS person_count
FROM (
  SELECT
    person_id,
    count(*) AS disease_rows_per_person
  FROM tmp_diag_disease
  GROUP BY person_id
) x
GROUP BY disease_rows_per_person
ORDER BY disease_rows_per_person DESC;

/* Persons most likely inflating the join */
WITH response_per_person AS (
  SELECT person_id, count(*) AS response_rows
  FROM tmp_diag_response
  GROUP BY person_id
),
disease_per_person AS (
  SELECT person_id, count(*) AS disease_rows
  FROM tmp_diag_disease
  GROUP BY person_id
)
SELECT
  r.person_id,
  r.response_rows,
  coalesce(d.disease_rows, 0) AS disease_rows,
  (r.response_rows * greatest(coalesce(d.disease_rows, 1), 1))::bigint AS expected_join_rows_for_person
FROM response_per_person r
LEFT JOIN disease_per_person d
  ON d.person_id = r.person_id
WHERE coalesce(d.disease_rows, 0) > 1
ORDER BY expected_join_rows_for_person DESC, r.person_id
LIMIT 100;

/*
   5) Which diabetes condition_concept_ids are driving multiplicity?
============================================================================ */
SELECT
  condition_concept_id,
  count(*) AS person_rows,
  count(DISTINCT person_id) AS distinct_persons
FROM tmp_diag_disease
GROUP BY condition_concept_id
ORDER BY person_rows DESC, distinct_persons DESC
LIMIT 100;

/* For persons with >1 diabetes concept, list concept combinations */
WITH per_person AS (
  SELECT
    person_id,
    array_agg(condition_concept_id ORDER BY condition_concept_id) AS concept_set
  FROM tmp_diag_disease
  GROUP BY person_id
  HAVING count(*) > 1
)
SELECT
  concept_set,
  count(*) AS person_count
FROM per_person
GROUP BY concept_set
ORDER BY person_count DESC
LIMIT 100;

/*
   6) Condition_occurrence duplicate quality check
      (same person + condition_concept_id repeated many times)
============================================================================ */
SELECT
  person_id,
  condition_concept_id,
  count(*) AS condition_occurrence_rows
FROM cdm.condition_occurrence
WHERE condition_concept_id IN (SELECT concept_id FROM tmp_diag_diabetes_concepts)
GROUP BY person_id, condition_concept_id
HAVING count(*) > 1
ORDER BY condition_occurrence_rows DESC, person_id
LIMIT 100;

/*
   7) Side-by-side comparison helper metrics
      Save this output from both CDMs; differences here usually explain behavior.
============================================================================ */
SELECT 'distinct_response_persons' AS metric, count(DISTINCT person_id)::bigint AS value FROM tmp_diag_response
UNION ALL
SELECT 'distinct_disease_persons', count(DISTINCT person_id)::bigint FROM tmp_diag_disease
UNION ALL
SELECT 'distinct_joined_persons', count(DISTINCT person_id)::bigint FROM tmp_diag_joined
UNION ALL
SELECT 'persons_with_0_disease_rows', count(*)::bigint
FROM (
  SELECT r.person_id
  FROM tmp_diag_response r
  LEFT JOIN tmp_diag_disease d ON d.person_id = r.person_id
  GROUP BY r.person_id
  HAVING count(d.condition_concept_id) = 0
) z
UNION ALL
SELECT 'persons_with_1_disease_row', count(*)::bigint
FROM (
  SELECT d.person_id
  FROM tmp_diag_disease d
  GROUP BY d.person_id
  HAVING count(*) = 1
) z
UNION ALL
SELECT 'persons_with_gt1_disease_rows', count(*)::bigint
FROM (
  SELECT d.person_id
  FROM tmp_diag_disease d
  GROUP BY d.person_id
  HAVING count(*) > 1
) z;

