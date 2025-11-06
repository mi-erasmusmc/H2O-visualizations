###Disease concepts-------------------------------------------------------------
#General query to retrieve the descendant concept ids
sqlDiseaseDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)", 
  targetDialect = sqlDialect
)

#Diabetes Concept Set
diabetesCS <- querySql(
  connection, 
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema,
    concepts = c(201826,4193704,4008576,201254)
    )
  )

#Inflammatory Bowel Disease Concept Set
ibdCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(201606,81893,194684)
    )
  )

#Breast cancer Concept Set
bcCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(4112853)
    )
  )

#Lung cancer Concept Set
lcCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(443388,4115276,40492938)
    )
  )

#Observation Concept Set
οbservationCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = c(46234708,1340204)
  )
)


### PROMIS_10 questionnaire concepts--------------------------------------------
questionConcepts <- c(40764338,40764339,40764340,40764341,40764342,40764343,
                      40764344,40764345,40764346,40764347)

