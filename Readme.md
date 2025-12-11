# General
This repository contains code to:
1. Recreate the H2O insights centre statistics based on querying directly the databases
2. Create visualizations for the PROMIS GLOBAL 10 questionnaire, which the H2O patients have answered doing recruitment and in subsequent times.

## Available data
- The H2O patients have been recruited to the project for one of the four conditions - Diabetes Melitus, Inflamatory Bowel Disease, Breast Cancer, Lung Cancer. 
- The code is intented to run against data from three hospitals available - Erasmus Medical Centre Rotterdam, Medical University of Vienna, Vall d'Hebron University Hospital Barcelona. 
- All data used are mapped to an [OMOP CDM](https://ohdsi.github.io/CommonDataModel/index.html) database.

# Custom observations

There are differences in how the patients are recruited for each disease in the hospitals above and for the analysis we aim to perform here in WPx we decided to create an additional observation, with a custom codes to represent the primary disease. We did so according to the OMOP CDM conventions for introducing [custom concepts](https://ohdsi.github.io/CommonDataModel/customConcepts.html).

### Custom Vocabulary
|Field|Value|
|---|---|
|vocabulary_id|H2O|
|vocabulary_name|H2O recruitment disease|
|vocabulary_version|2025-12-10|
|vocabulary_concept_id|0|

### Custom concepts
|Field|Concept 1|Concept 2|Concept 3|Concept 4|
|---|---|---|---|---|
|concept_id|2010000001|2010000002|2010000003|2010000004|
|concept_name|H2O Diabetes patient|H2O Inflammatory Bowel Disease patient|H2O Breast Cancer patient|H2O Lung Cancer patient|
|domain_id|Observation|Observation|Observation|Observation|
|vocabulary_id|H2O|H2O|H2O|H2O|
|concept_class_id|Undefined|Undefined|Undefined|Undefined|
|standard_concept|NULL|NULL|NULL|NULL|
|concept_code|0|0|0|0|
|valid_start_date|2020-10-01|2020-10-01|2020-10-01|2020-10-01|
|valid_end_date|2099-12-31|2099-12-31|2099-12-31|2099-12-31|
|invalid_reason|NULL|NULL|NULL|NULL|

### Observation record
|Field|Value|Comment|
|---|---|---|
|observation_id||auto increment|
|person_id|||
|observation_concept_id|44807982|Participant in research study|
|observation_date|2020-10-01|Start of H2O project|
|value_as_concept_id|custom_concept_id||
|value_source_value|custom_concept_name||
|observation_type_concept_id|32862|Patient filled survey|

### Sample insert code
Sample code to insert the new records in the Observation table for postgresql can be found in `insert_custom.sql`

# How to use
## Single database

## Multiple databases

# Plots
## Insights centre
- Histograms

## PROMIS GLOBAL 10
- Boxplot