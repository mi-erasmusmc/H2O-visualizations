# General
This repository contains code to:
1. Recreate the H2O insights centre statistics based on querying directly the databases
2. Create visualizations for the PROMIS GLOBAL 10 questionnaire, which the H2O patients have answered doing recruitment and in subsequent times.

### Available data
- The H2O patients have been recruited to the project for one of the four conditions - Diabetes Melitus, Inflamatory Bowel Disease, Breast Cancer, Lung Cancer. 
- The code is intented to run against data from three hospitals available - Erasmus Medical Centre Rotterdam, Medical University of Vienna, Vall d'Hebron University Hospital Barcelona. 
- All data used are mapped to an [OMOP CDM](https://ohdsi.github.io/CommonDataModel/index.html) database.

# Custom observations     
There are differences in how the patients are recruited for each disease in the hospitals above and for the analysis we aim to perform here we decided to create an additional observation, with a custom codes to represent the primary disease. The `observation_concept_id` would still consist of a standard concept `44807982, Participant in research study` and the custom concept will represent the `value_as_concept_id`. 

Adding the custom concepts in the vocabulary tables and the observation table as seen below.

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
|concept_name|H2O Diabetes|H2O Inflammatory Bowel Disease|H2O Breast Cancer|H2O Lung Cancer|
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
Sample code to insert the new records in the Observation table for postgresql can be found in `extra/insert_custom.sql`

# How to use
#### Single database
All the scripts that need to run to gather the nessasery counts and create the visualizations can be found in `code_to_run.R`.

#### Multiple databases
In case the data are split by disease in different databases (case in one of the sites) the code will run in each database and combine the results into one afterwards. This can be done with the `code_to_run_multiple_dbs.R`.

#### Combine results
If all results are available in one place they can be combined so the plots can represent the same result for each site. In that case at the end of `code_to_run.R` there is an additional option to run script `visualizations_insights_centre_all.R` and `visualizations_promis10_all.R` for the visualizations.

# Plots
## Insights centre
- Person counts stratified by Age and by Gender
- Disease counts
- Diabetes therapy counts
    - Concepts and their descentants are used as agreed in the [20250221 PROMOP H2O dictionary_pragmatic set_Marko&Lau_AnswerSet](https://teamitresearch.sharepoint.com/:x:/r/sites/HOO/_layouts/15/Doc.aspx?sourcedoc=%7B0B80E0B5-D0CF-46F3-916B-A8DF5E3C6F8C%7D&file=20250221%20PROMOP%20H2O%20dictionary_pragmatic%20set_Marko%26Lau_AnswerSet.xlsx&action=default&mobileredirect=true)
- Diabetes diagnostics 
    - Hb1Ac measurement over time. Not yet availale in the insights centre but interesting to add.

## PROMIS GLOBAL 10
- Number of times a questionnaire was answered per question group (general health, quality of life, physical health and mental health)
- T-scores according to [PROMIS Global Health Scoring Manual](www.healthmeasures.net/images/PROMIS/manuals/Scoring_Manual_Only/PROMIS_Global_Health_Scoring_Manual_30Aug2024.pdf) for physical and mental health
- Mean and standard error for each answer time for the PROMIS global 10 General Health group
- Transitions between responses for the PROMIS global 10 General Health group