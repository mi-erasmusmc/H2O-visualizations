sqlPromis10 <- translate(
  "with disease as (
      SELECT 
        person_id, 
        value_as_concept_id
      FROM @databaseSchema.observation
          WHERE observation_concept_id = 44807982
             and value_as_concept_id IN (@diseaseConcepts)
   ), response as (
       select person_id, 
              observation_concept_id, 
              value_as_concept_id,
              observation_date
       from @databaseSchema.observation
       where observation_concept_id in (@questionConcepts)
   )
   select response.person_id,
       response.observation_concept_id as question_concept_id, 
       response.value_as_concept_id as answer_concept_id,
       response.observation_date as questionnaire_date,
       disease.value_as_concept_id as disease_concept_id
   from response
   left join disease
       on disease.person_id = response.person_id
   order by response.person_id, response.observation_date asc",
  targetDialect = sqlDialect
)
