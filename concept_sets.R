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
names(diabetesCS) <- tolower(names(diabetesCS))  # MUW: since oracle returns upper case column names
diabetesCS <- rbind(diabetesCS, data.frame(concept_id = c(201820,37018196))) # MUW (Diabetes mellitus, Prediabetes)


#Inflammatory Bowel Disease Concept Set
ibdCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(201606,81893,194684,
                 4074815) # MUW (Inflammatory bowel disease)
    )
  )
names(ibdCS) <- tolower(names(ibdCS))  # MUW: since oracle returns upper case column names

#Breast cancer Concept Set
bcCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(4112853, 
                 81250) # MUW ("Carcinoma in situ of breast"), subsumes other concepts in use, e.g.: 601142,4116071, 609066
    )
  )
names(bcCS) <- tolower(names(bcCS))  # MUW: since oracle returns upper case column names
bcCS <- rbind(bcCS, data.frame(concept_id = c(759932,36712724,36684818,759933,36712725,765123)))  # MUW: outdated concepts that are still in use at our databases

#Lung cancer Concept Set
lcCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema, 
    concepts = c(443388,4115276,40492938)
    )
  )
names(lcCS) <- tolower(names(lcCS))  # MUW: since oracle returns upper case column names

#Observation Concept Set
observationCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = c(46234708,1340204)
  )
)
names(observationCS) <- tolower(names(observationCS))  # MUW: since oracle returns upper case column names


### PROMIS_10 questionnaire concepts--------------------------------------------
questionConcepts <- c(40764338,40764339,40764340,40764341,40764342,40764343,
                      40764344,40764345,40764346,40764347)

