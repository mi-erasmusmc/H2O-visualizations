-- sample code inserting new vocabulary
insert into cdm_name.vocabulary (
    vocabulary_id,
    vocabulary_name,
    vocabulary_version,
    vocabulary_concept_id
)
values (
    'H2O',
    'H2O recruitment disease',
    '2025-12-10',
    0
);


-- sample code inserting custom concept
insert into cdm_name.concept (
    concept_id,
    concept_name,
    domain_id,
    vocabulary_id,
    concept_class_id,
    standard_concept,
    concept_code,
    valid_start_date,
    valid_end_date,
    invalid_reason
)
values (
    2010000001,
    'H2O Diabetes',
    'Observation',
    'H2O',
    'Undefined',
    NULL,
    0,
    '2020-10-01',
    '2099-12-31',
    NULL
);


-- sample code for inserting new observation record for patient
-- with primary disease from the condition table
with max_id as (
	select coalesce(max(observation_id), 0) as max_id
	from cdm_name.observation
), rows_to_insert as (
	select person_id, row_number() over (order by person_id) as rn
	from cdm_name.condition_occurrence
	where condition_concept_id = 201820 -- diabetes melitus
)
insert into cdm_name.observation (
	observation_id, 
	person_id, 
	observation_concept_id,
	observation_source_concept_id,
	observation_date,
	value_as_string,
	observation_type_concept_id
)
select
	max_id.max_id + rows_to_insert.rn, 
	rows_to_insert.person_id, 
	44807982, -- Participant in research study
	2010000001, -- custom concept for H2O Diabetes
	'2020-10-01', -- start of H2O project
	'H2O Diabetes', -- custom concept name
	32862 -- Patient filled survey
from rows_to_insert
cross join max_id;

select * from cdm_name.observation;

