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
# MUW Concept IDs derived from the related values data dictionary MUW (measurements table)
hba1cConcept_MUW             <- c(3004410)  
cholesterolTotalConcept_MUW  <- c(4008265)
cholesterolLdlConcept_MUW    <- c(2212451) # not used in the graphes
cholesterolHdlConcept_MUW    <- c(2212449) # not used in the graphes
triglyceridesConcept_MUW     <- c(4017787)
bpSystolicConcept_MUW        <- c(4152194)
bpDiastolicConcept_MUW       <- c(4154790) 




# EMC Concept IDs derived from the related values data dictionary (observation table)
hba1cConcept_EMC             <- c(3004410)  
cholesterolTotalConcept_EMC  <- c(3019900)
cholesterolLdlConcept_EMC    <- c(3001308) # not used in the graphes
cholesterolHdlConcept_EMC    <- c(3023602) # not used in the graphes
triglyceridesConcept_EMC     <- c(3025839)
bpSystolicConcept_EMC        <- c(3004249)
bpDiastolicConcept_EMC       <- c(3012888)


# Combine all clinical concepts into one list to pass to SQL
clinicalConcepts_MUW <- c(
  hba1cConcept_MUW,
  cholesterolTotalConcept_MUW,
  cholesterolLdlConcept_MUW,
  cholesterolHdlConcept_MUW,
  triglyceridesConcept_MUW,
  bpSystolicConcept_MUW,
  bpDiastolicConcept_MUW
)


clinicalConcepts_EMC <- c(
  hba1cConcept_EMC,
  cholesterolTotalConcept_EMC,
  cholesterolLdlConcept_EMC,
  cholesterolHdlConcept_EMC,
  triglyceridesConcept_EMC,
  bpSystolicConcept_EMC,
  bpDiastolicConcept_EMC
)