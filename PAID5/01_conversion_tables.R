###
conversionQuestionCTS <- tibble(
  question_concept_id = c(
    40768166,
    1761895,
    1989000,
    42690315,
    4112552
  ),
  question_number = c(
    '5_1', '5_2', '5_3', '5_4', '5_5'
  )
)

###Map concept_ids to the corresponding numeric value for calculations----------
conversionAnswerCTN <- tibble(
  answer_concept_id = c(
    21499256, 1177370, 45877983, 1177250, 45883536

  ),
  answer_value = c(
    0, 1, 2, 3, 4

  )
)

### PAID questionnaire concepts--------------------------------------------
questionConcepts <- c(
  40768166,
  1761895,
  1989000,
  42690315,
  4112552
)

### Clinical Measurement Concepts------------------------------------------
# Concept IDs derived from the related values data dictionary
hba1cConcept             <- c(3004410)
cholesterolTotalConcept  <- c(4008265)
cholesterolLdlConcept    <- c(2212451)
cholesterolHdlConcept    <- c(2212449)
triglyceridesConcept     <- c(4017787)
bpSystolicConcept        <- c(4152194)
bpDiastolicConcept       <- c(4154790) 

# Combine all clinical concepts into one list to pass to SQL
clinicalConcepts <- c(
  hba1cConcept,
  cholesterolTotalConcept,
  cholesterolLdlConcept,
  cholesterolHdlConcept,
  triglyceridesConcept,
  bpSystolicConcept,
  bpDiastolicConcept
)