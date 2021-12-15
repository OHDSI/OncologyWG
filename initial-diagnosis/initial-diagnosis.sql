DROP TABLE IF EXISTS tumor_registry_diagnoses;
CREATE TABLE tumor_registry_diagnoses(
  cancer_type                       varchar(255) NULL,
  condition_occurrence_id           BIGINT,
  condition_concept_id              BIGINT,
  person_id                         BIGINT,
  condition_start_date              date NULL,
  histology                         varchar(255) NULL,
  site                              varchar(255) NULL,
  histology_site                    varchar(255) NULL
);

INSERT INTO tumor_registry_diagnoses
(
  condition_occurrence_id
, condition_concept_id
, person_id
, condition_start_date
)
SELECT          condition_occurrence.condition_occurrence_id
              , condition_occurrence.condition_concept_id
              , condition_occurrence.person_id
              , condition_occurrence.condition_start_date
FROM condition_occurrence
WHERE condition_occurrence.condition_type_concept_id = 32535; --Tumor Registry

UPDATE tumor_registry_diagnoses
SET   histology_site = c1.concept_code
    , histology      = c2.concept_code
FROM concept_relationship cr1 JOIN concept c1 ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'ICDO3'
                              JOIN concept_relationship cr2 ON c1.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Has Histology ICDO'
                              JOIN concept c2 ON cr2.concept_id_2 = c2.concept_id
WHERE tumor_registry_diagnoses.condition_concept_id = cr1.concept_id_1
AND cr1.relationship_id = 'Mapped from';


UPDATE tumor_registry_diagnoses
SET   histology_site = c1.concept_code
    , site           = c2.concept_code
FROM concept_relationship cr1 JOIN concept c1 ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'ICDO3'
                              JOIN concept_relationship cr2 ON c1.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Has Topography ICDO'
                              JOIN concept c2 ON cr2.concept_id_2 = c2.concept_id
WHERE tumor_registry_diagnoses.condition_concept_id = cr1.concept_id_1
AND cr1.relationship_id = 'Mapped from' ;

UPDATE tumor_registry_diagnoses
SET cancer_type = 'Breast'
WHERE site IN(
  'C50.0'
 ,'C50.1'
 ,'C50.2'
 ,'C50.3'
 ,'C50.4'
 ,'C50.5'
 ,'C50.6'
 ,'C50.8'
 ,'C50.9'
);

UPDATE tumor_registry_diagnoses
SET cancer_type = 'Prostate'
WHERE site IN(
  'C61.9'
);

UPDATE tumor_registry_diagnoses
SET cancer_type = 'Pancreas'
WHERE site IN(
  'C25.0'
 ,'C25.1'
 ,'C25.2'
 ,'C25.3'
 ,'C25.4'
 ,'C25.7'
 ,'C25.8'
 ,'C25.9'
);

DROP TABLE IF EXISTS breast_concepts;
CREATE TABLE breast_concepts(
  concept_id                    BIGINT
);

INSERT INTO breast_concepts
(
  concept_id
)
SELECT ca.descendant_concept_id
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to'
                JOIN concept_ancestor ca ON  cr1.concept_id_2 = ca.ancestor_concept_id
WHERE c1.vocabulary_id IN('ICD10CM','ICD9CM')
AND c1.concept_code IN(
--ICD10CM
 'C50'
,'C50.0'
,'C50.01'
,'C50.011'
,'C50.012'
,'C50.019'
,'C50.02'
,'C50.021'
,'C50.022'
,'C50.029'
,'C50.1'
,'C50.11'
,'C50.111'
,'C50.112'
,'C50.119'
,'C50.12'
,'C50.121'
,'C50.122'
,'C50.129'
,'C50.2'
,'C50.21'
,'C50.211'
,'C50.212'
,'C50.219'
,'C50.22'
,'C50.221'
,'C50.222'
,'C50.229'
,'C50.3'
,'C50.31'
,'C50.311'
,'C50.312'
,'C50.319'
,'C50.32'
,'C50.321'
,'C50.322'
,'C50.329'
,'C50.4'
,'C50.41'
,'C50.411'
,'C50.412'
,'C50.419'
,'C50.42'
,'C50.421'
,'C50.422'
,'C50.429'
,'C50.5'
,'C50.51'
,'C50.511'
,'C50.512'
,'C50.519'
,'C50.52'
,'C50.521'
,'C50.522'
,'C50.529'
,'C50.6'
,'C50.61'
,'C50.611'
,'C50.612'
,'C50.619'
,'C50.62'
,'C50.621'
,'C50.622'
,'C50.629'
,'C50.8'
,'C50.81'
,'C50.811'
,'C50.812'
,'C50.819'
,'C50.82'
,'C50.821'
,'C50.822'
,'C50.829'
,'C50.9'
,'C50.91'
,'C50.911'
,'C50.912'
,'C50.919'
,'C50.92'
,'C50.921'
,'C50.922'
,'C50.929'
,'Z85.3'
--ICD9CM
,'174'
,'174.0'
,'174.1'
,'174.2'
,'174.3'
,'174.4'
,'174.5'
,'174.6'
,'174.8'
,'174.9'
,'V10.3'
);

DROP TABLE IF EXISTS prostate_concepts;
CREATE TABLE prostate_concepts(
  concept_id                    BIGINT
);

INSERT INTO prostate_concepts
(
  concept_id
)
SELECT ca.descendant_concept_id
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to'
                JOIN concept_ancestor ca ON  cr1.concept_id_2 = ca.ancestor_concept_id
WHERE c1.vocabulary_id IN('ICD10CM','ICD9CM')
AND c1.concept_code IN(
--ICD10CM
  'C61'
, 'Z85.46'
--ICD9CM
, '185'
, 'V10.46'
);


DROP TABLE IF EXISTS pancreas_concepts;
CREATE TABLE pancreas_concepts(
  concept_id                    BIGINT
);

INSERT INTO pancreas_concepts
(
  concept_id
)
SELECT ca.descendant_concept_id
FROM concept c1 JOIN concept_relationship cr1 ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to'
                JOIN concept_ancestor ca ON  cr1.concept_id_2 = ca.ancestor_concept_id
WHERE c1.vocabulary_id IN('ICD10CM','ICD9CM')
AND c1.concept_code IN(
--ICD10CM
 'C25'
,'C25.0'
,'C25.1'
,'C25.2'
,'C25.3'
,'C25.4'
,'C25.7'
,'C25.8'
,'C25.9'
,'Z85.07'
--ICD9CM
, '157'
,'157.0'
,'157.1'
,'157.2'
,'157.3'
,'157.4'
,'157.8'
,'157.9'
,'V10.46'
);

DROP TABLE IF EXISTS breast_clinical_diagnoses;
CREATE TABLE breast_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date
);

INSERT INTO breast_clinical_diagnoses
(
    person_id
 , diagnosis_start_date
)
SELECT  condition_occurrence.person_id
      , MIN(condition_occurrence.condition_start_date)    AS diagnosis_start_date
FROM condition_occurrence JOIN breast_concepts ON condition_occurrence.condition_concept_id = breast_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
GROUP BY condition_occurrence.person_id;

DROP TABLE IF EXISTS prostate_clinical_diagnoses;
CREATE TABLE prostate_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date
);

INSERT INTO prostate_clinical_diagnoses
(
    person_id
 , diagnosis_start_date
)
SELECT  condition_occurrence.person_id
      , MIN(condition_occurrence.condition_start_date)    AS diagnosis_start_date
FROM condition_occurrence JOIN prostate_concepts ON condition_occurrence.condition_concept_id = prostate_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
GROUP BY condition_occurrence.person_id;

DROP TABLE IF EXISTS pancreas_clinical_diagnoses;
CREATE TABLE pancreas_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date
);

INSERT INTO pancreas_clinical_diagnoses
(
    person_id
 , diagnosis_start_date
)
SELECT  condition_occurrence.person_id
      , MIN(condition_occurrence.condition_start_date)    AS diagnosis_start_date
FROM condition_occurrence JOIN pancreas_concepts ON condition_occurrence.condition_concept_id = pancreas_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
GROUP BY condition_occurrence.person_id;


DROP TABLE IF EXISTS patients;

CREATE TABLE patients(
  cancer_type                                                   varchar(255)  NULL,
  person_id                                                     BIGINT        NULL,
  -- deidentified_person_id                                        BIGINT        NULL,
  condition_occurrence_id                                       BIGINT        NULL,
  registry_diagnosis_date_minus_ehr_diagnosis_date              BIGINT        NULL,
  registry_diagnosis_date                                       date          NULL,
  ehr_diagnosis_date                                            date          NULL,
  second_ehr_diagnosis_date                                     date          NULL,
  closest_biopsy_date_minus_registry_diagnosis_date             BIGINT        NULL,
  closest_biopsy_date_minus_ehr_diagnosis_date                  BIGINT        NULL,
  closest_resection_date_minus_registry_diagnosis_date          BIGINT        NULL,
  closest_resection_date_minus_ehr_diagnosis_date               BIGINT        NULL,
  closest_outside_biopsy_date_minus_registry_diagnosis_date     BIGINT        NULL,
  closest_outside_biopsy_date_minus_ehr_diagnosis_date          BIGINT        NULL,
  second_ehr_diagnosis_date_minus_first_ehr_diagnosis_date      BIGINT        NULL,
--prostate only
  closest_bladder_biopsy_date_minus_registry_diagnosis_date     BIGINT        NULL,
  closest_bladder_biopsy_date_minus_ehr_diagnosis_date          BIGINT        NULL,
  closest_bladder_resection_date_minus_registry_diagnosis_date  BIGINT        NULL,
  closest_bladder_resection_date_minus_ehr_diagnosis_date       BIGINT        NULL
);

INSERT INTO patients
(
   cancer_type
,  person_id
-- ,  deidentified_person_id
,  condition_occurrence_id
,  registry_diagnosis_date
,  ehr_diagnosis_date
,  registry_diagnosis_date_minus_ehr_diagnosis_date
)
SELECT  tumor_registry_diagnoses.cancer_type
      , tumor_registry_diagnoses.person_id
      -- , row_number() over(ORDER BY tumor_registry_diagnoses.person_id desc) as deidentified_person_id
      , tumor_registry_diagnoses.condition_occurrence_id
      , tumor_registry_diagnoses.condition_start_date AS registry_diagnosis_date
      , breast_clinical_diagnoses.diagnosis_start_date AS ehr_diagnosis_date
      , tumor_registry_diagnoses.condition_start_date - breast_clinical_diagnoses.diagnosis_start_date AS days
FROM  tumor_registry_diagnoses LEFT JOIN breast_clinical_diagnoses ON tumor_registry_diagnoses.person_id = breast_clinical_diagnoses.person_id
WHERE tumor_registry_diagnoses.cancer_type = 'Breast';

INSERT INTO patients
(
   cancer_type
,  person_id
-- ,  deidentified_person_id
,  condition_occurrence_id
,  registry_diagnosis_date
,  ehr_diagnosis_date
,  registry_diagnosis_date_minus_ehr_diagnosis_date
)
SELECT  tumor_registry_diagnoses.cancer_type
      , tumor_registry_diagnoses.person_id
      -- , row_number() over(ORDER BY tumor_registry_diagnoses.person_id desc) as deidentified_person_id
      , tumor_registry_diagnoses.condition_occurrence_id
      , tumor_registry_diagnoses.condition_start_date AS registry_diagnosis_date
      , prostate_clinical_diagnoses.diagnosis_start_date AS ehr_diagnosis_date
      , tumor_registry_diagnoses.condition_start_date - prostate_clinical_diagnoses.diagnosis_start_date AS days
FROM  tumor_registry_diagnoses LEFT JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE tumor_registry_diagnoses.cancer_type = 'Prostate';

INSERT INTO patients
(
   cancer_type
,  person_id
-- ,  deidentified_person_id
,  condition_occurrence_id
,  registry_diagnosis_date
,  ehr_diagnosis_date
,  registry_diagnosis_date_minus_ehr_diagnosis_date
)
SELECT  tumor_registry_diagnoses.cancer_type
      , tumor_registry_diagnoses.person_id
      -- , row_number() over(ORDER BY tumor_registry_diagnoses.person_id desc) as deidentified_person_id
      , tumor_registry_diagnoses.condition_occurrence_id
      , tumor_registry_diagnoses.condition_start_date AS registry_diagnosis_date
      , pancreas_clinical_diagnoses.diagnosis_start_date AS ehr_diagnosis_date
      , tumor_registry_diagnoses.condition_start_date - pancreas_clinical_diagnoses.diagnosis_start_date AS days
FROM  tumor_registry_diagnoses LEFT JOIN pancreas_clinical_diagnoses ON tumor_registry_diagnoses.person_id = pancreas_clinical_diagnoses.person_id
WHERE tumor_registry_diagnoses.cancer_type = 'Pancreas';

DROP TABLE IF EXISTS breast_biopsies;
CREATE TABLE breast_biopsies(
  person_id                     BIGINT       NULL,
  biopsy_date                   date         NULL
);

INSERT INTO breast_biopsies (
  person_id
, biopsy_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4047494; --Biopsy of breast

DROP TABLE IF EXISTS breast_resections;
CREATE TABLE breast_resections(
  person_id                     BIGINT       NULL,
  resection_date                date         NULL
);

INSERT INTO breast_resections (
  person_id
, resection_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4286804;  --Excision of breast tissue

DROP TABLE IF EXISTS prostate_biopsies;
CREATE TABLE prostate_biopsies(
  person_id                     BIGINT       NULL,
  biopsy_date                   date         NULL
);

INSERT INTO prostate_biopsies (
  person_id
, biopsy_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4278515; --Biopsy of prostate


DROP TABLE IF EXISTS prostate_resections;
CREATE TABLE prostate_resections(
  person_id                     BIGINT       NULL,
  resection_date                date         NULL
);

INSERT INTO prostate_resections (
  person_id
, resection_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4235738;  --Prostatectomy


DROP TABLE IF EXISTS pancreas_biopsies;
CREATE TABLE pancreas_biopsies(
  person_id                     BIGINT       NULL,
  biopsy_date                   date         NULL
);

INSERT INTO pancreas_biopsies (
  person_id
, biopsy_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4138981; --Biopsy of pancreas


DROP TABLE IF EXISTS pancreas_resections;
CREATE TABLE pancreas_resections(
  person_id                     BIGINT       NULL,
  resection_date                date         NULL
);

INSERT INTO pancreas_resections (
  person_id
, resection_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4141456;  --Pancreatectomy

DROP TABLE IF EXISTS bladder_biopsies;
CREATE TABLE bladder_biopsies(
  person_id                     BIGINT       NULL,
  biopsy_date                   date         NULL
);

INSERT INTO bladder_biopsies (
  person_id
, biopsy_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4267975; --Biopsy of bladder

DROP TABLE IF EXISTS bladder_resections;
CREATE TABLE bladder_resections(
  person_id                     BIGINT       NULL,
  resection_date                date         NULL
);

INSERT INTO bladder_resections (
  person_id
, resection_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4029571;  --Bladder excision


DROP TABLE IF EXISTS outside_biopsies;
CREATE TABLE outside_biopsies(
  person_id                     BIGINT       NULL,
  biopsy_date                   date         NULL
);

INSERT INTO outside_biopsies (
  person_id
, biopsy_date
)
SELECT  procedure_occurrence.person_id
      , procedure_occurrence.procedure_date
FROM procedure_occurrence JOIN concept_ancestor ca ON procedure_occurrence.procedure_concept_id = ca.descendant_concept_id AND ca.ancestor_concept_id = 4244107; --Surgical pathology consultation and report on referred slides prepared elsewhere

DROP TABLE IF EXISTS closest_breast_biopsies_tumor_registry;
CREATE TABLE closest_breast_biopsies_tumor_registry(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_breast_biopsies_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_registry_diagnosis_date
)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date_abs
      , data.closest_biopsy_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(breast_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date) AS closest_biopsy_date_minus_registry_diagnosis_date_abs
        , breast_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date AS closest_biopsy_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN breast_biopsies ON tumor_registry_diagnoses.person_id = breast_biopsies.person_id
WHERE cancer_type = 'Breast'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_registry_diagnosis_date = closest_breast_biopsies_tumor_registry.closest_biopsy_date_minus_registry_diagnosis_date
FROM closest_breast_biopsies_tumor_registry
WHERE patients.person_id = closest_breast_biopsies_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_breast_biopsies_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_breast_biopsies_ehr;
CREATE TABLE closest_breast_biopsies_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_ehr_diagnosis_date        BIGINT       NULL
);

INSERT INTO closest_breast_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(breast_biopsies.biopsy_date - breast_clinical_diagnoses.diagnosis_start_date) AS closest_biopsy_date_minus_ehr_diagnosis_date_abs
        , breast_biopsies.biopsy_date - breast_clinical_diagnoses.diagnosis_start_date AS closest_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN breast_biopsies           ON tumor_registry_diagnoses.person_id = breast_biopsies.person_id
                              JOIN breast_clinical_diagnoses ON tumor_registry_diagnoses.person_id = breast_clinical_diagnoses.person_id
WHERE cancer_type = 'Breast'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_ehr_diagnosis_date = closest_breast_biopsies_ehr.closest_biopsy_date_minus_ehr_diagnosis_date
FROM closest_breast_biopsies_ehr
WHERE patients.person_id = closest_breast_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_breast_biopsies_ehr.condition_occurrence_id;

DROP TABLE IF EXISTS closest_breast_resections_tumor_registry;
CREATE TABLE closest_breast_resections_tumor_registry(
  person_id                                              BIGINT       NULL,
  condition_occurrence_id                                BIGINT       NULL,
  closest_resection_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_breast_resections_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_registry_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date_abs
      , data.closest_resection_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(breast_resections.resection_date - tumor_registry_diagnoses.condition_start_date) AS closest_resection_date_minus_registry_diagnosis_date_abs
        , breast_resections.resection_date - tumor_registry_diagnoses.condition_start_date AS closest_resection_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN breast_resections ON tumor_registry_diagnoses.person_id = breast_resections.person_id
WHERE cancer_type = 'Breast'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_registry_diagnosis_date = closest_breast_resections_tumor_registry.closest_resection_date_minus_registry_diagnosis_date
FROM closest_breast_resections_tumor_registry
WHERE patients.person_id = closest_breast_resections_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_breast_resections_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_breast_resections_ehr;
CREATE TABLE closest_breast_resections_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_resection_date_minus_ehr_diagnosis_date     BIGINT       NULL
);

INSERT INTO closest_breast_resections_ehr
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date_abs
      , data.closest_resection_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(breast_resections.resection_date - breast_clinical_diagnoses.diagnosis_start_date) AS closest_resection_date_minus_ehr_diagnosis_date_abs
        , breast_resections.resection_date - breast_clinical_diagnoses.diagnosis_start_date AS closest_resection_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN breast_resections         ON tumor_registry_diagnoses.person_id = breast_resections.person_id
                              JOIN breast_clinical_diagnoses ON tumor_registry_diagnoses.person_id = breast_clinical_diagnoses.person_id
WHERE cancer_type = 'Breast'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_ehr_diagnosis_date = closest_breast_resections_ehr.closest_resection_date_minus_ehr_diagnosis_date
FROM closest_breast_resections_ehr
WHERE patients.person_id = closest_breast_resections_ehr.person_id
AND patients.condition_occurrence_id = closest_breast_resections_ehr.condition_occurrence_id;

DROP TABLE IF EXISTS closest_outside_biopsies_tumor_registry;
CREATE TABLE closest_outside_biopsies_tumor_registry(
  person_id                                                   BIGINT       NULL,
  condition_occurrence_id                                     BIGINT       NULL,
  closest_outside_biopsy_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_outside_biopsies_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_outside_biopsy_date_minus_registry_diagnosis_date

)
SELECT  data.person_id                                                AS patient_ir_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_registry_diagnosis_date_abs
      , data.closest_outside_biopsy_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_outside_biopsy_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(outside_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date) AS closest_outside_biopsy_date_minus_registry_diagnosis_date_abs
        , outside_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date AS closest_outside_biopsy_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN outside_biopsies ON tumor_registry_diagnoses.person_id = outside_biopsies.person_id
WHERE cancer_type IN('Breast', 'Prostate', 'Pancreas')
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_outside_biopsy_date_minus_registry_diagnosis_date = closest_outside_biopsies_tumor_registry.closest_outside_biopsy_date_minus_registry_diagnosis_date
FROM closest_outside_biopsies_tumor_registry
WHERE patients.person_id = closest_outside_biopsies_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_outside_biopsies_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_outside_biopsies_ehr;
CREATE TABLE closest_outside_biopsies_ehr(
  person_id                                             BIGINT       NULL,
  condition_occurrence_id                               BIGINT       NULL,
  closest_outside_biopsy_date_minus_ehr_diagnosis_date  BIGINT       NULL
);

INSERT INTO closest_outside_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_outside_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(outside_biopsies.biopsy_date - breast_clinical_diagnoses.diagnosis_start_date) AS closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
        , outside_biopsies.biopsy_date - breast_clinical_diagnoses.diagnosis_start_date AS closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN outside_biopsies           ON tumor_registry_diagnoses.person_id = outside_biopsies.person_id
                              JOIN breast_clinical_diagnoses ON tumor_registry_diagnoses.person_id = breast_clinical_diagnoses.person_id
WHERE cancer_type IN('Breast')
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_outside_biopsy_date_minus_ehr_diagnosis_date = closest_outside_biopsies_ehr.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM closest_outside_biopsies_ehr
WHERE patients.person_id = closest_outside_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_outside_biopsies_ehr.condition_occurrence_id;

TRUNCATE TABLE closest_outside_biopsies_ehr;
INSERT INTO closest_outside_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_outside_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(outside_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date) AS closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
        , outside_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date AS closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN outside_biopsies           ON tumor_registry_diagnoses.person_id = outside_biopsies.person_id
                              JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE cancer_type IN('Prostate')
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_outside_biopsy_date_minus_ehr_diagnosis_date = closest_outside_biopsies_ehr.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM closest_outside_biopsies_ehr
WHERE patients.person_id = closest_outside_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_outside_biopsies_ehr.condition_occurrence_id;


TRUNCATE TABLE closest_outside_biopsies_ehr;

INSERT INTO closest_outside_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_outside_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_outside_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(outside_biopsies.biopsy_date - pancreas_clinical_diagnoses.diagnosis_start_date) AS closest_outside_biopsy_date_minus_ehr_diagnosis_date_abs
        , outside_biopsies.biopsy_date - pancreas_clinical_diagnoses.diagnosis_start_date AS closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN outside_biopsies           ON tumor_registry_diagnoses.person_id = outside_biopsies.person_id
                              JOIN pancreas_clinical_diagnoses ON tumor_registry_diagnoses.person_id = pancreas_clinical_diagnoses.person_id
WHERE cancer_type IN('Pancreas')
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_outside_biopsy_date_minus_ehr_diagnosis_date = closest_outside_biopsies_ehr.closest_outside_biopsy_date_minus_ehr_diagnosis_date
FROM closest_outside_biopsies_ehr
WHERE patients.person_id = closest_outside_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_outside_biopsies_ehr.condition_occurrence_id;


DROP TABLE IF EXISTS closest_prostate_biopsies_tumor_registry;
CREATE TABLE closest_prostate_biopsies_tumor_registry(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_prostate_biopsies_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_registry_diagnosis_date
)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date_abs
      , data.closest_biopsy_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(prostate_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date) AS closest_biopsy_date_minus_registry_diagnosis_date_abs
        , prostate_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date AS closest_biopsy_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN prostate_biopsies ON tumor_registry_diagnoses.person_id = prostate_biopsies.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_registry_diagnosis_date = closest_prostate_biopsies_tumor_registry.closest_biopsy_date_minus_registry_diagnosis_date
FROM closest_prostate_biopsies_tumor_registry
WHERE patients.person_id = closest_prostate_biopsies_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_prostate_biopsies_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_prostate_biopsies_ehr;
CREATE TABLE closest_prostate_biopsies_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_ehr_diagnosis_date        BIGINT       NULL
);

INSERT INTO closest_prostate_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(prostate_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date) AS closest_biopsy_date_minus_ehr_diagnosis_date_abs
        , prostate_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date AS closest_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN prostate_biopsies           ON tumor_registry_diagnoses.person_id = prostate_biopsies.person_id
                              JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_ehr_diagnosis_date = closest_prostate_biopsies_ehr.closest_biopsy_date_minus_ehr_diagnosis_date
FROM closest_prostate_biopsies_ehr
WHERE patients.person_id = closest_prostate_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_prostate_biopsies_ehr.condition_occurrence_id;

DROP TABLE IF EXISTS closest_prostate_resections_tumor_registry;
CREATE TABLE closest_prostate_resections_tumor_registry(
  person_id                                              BIGINT       NULL,
  condition_occurrence_id                                BIGINT       NULL,
  closest_resection_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_prostate_resections_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_registry_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date_abs
      , data.closest_resection_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(prostate_resections.resection_date - tumor_registry_diagnoses.condition_start_date) AS closest_resection_date_minus_registry_diagnosis_date_abs
        , prostate_resections.resection_date - tumor_registry_diagnoses.condition_start_date AS closest_resection_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN prostate_resections ON tumor_registry_diagnoses.person_id = prostate_resections.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_registry_diagnosis_date = closest_prostate_resections_tumor_registry.closest_resection_date_minus_registry_diagnosis_date
FROM closest_prostate_resections_tumor_registry
WHERE patients.person_id = closest_prostate_resections_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_prostate_resections_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_prostate_resections_ehr;
CREATE TABLE closest_prostate_resections_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_resection_date_minus_ehr_diagnosis_date     BIGINT       NULL
);

INSERT INTO closest_prostate_resections_ehr
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date_abs
      , data.closest_resection_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(prostate_resections.resection_date - prostate_clinical_diagnoses.diagnosis_start_date) AS closest_resection_date_minus_ehr_diagnosis_date_abs
        , prostate_resections.resection_date - prostate_clinical_diagnoses.diagnosis_start_date AS closest_resection_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN prostate_resections         ON tumor_registry_diagnoses.person_id = prostate_resections.person_id
                              JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_ehr_diagnosis_date = closest_prostate_resections_ehr.closest_resection_date_minus_ehr_diagnosis_date
FROM closest_prostate_resections_ehr
WHERE patients.person_id = closest_prostate_resections_ehr.person_id
AND patients.condition_occurrence_id = closest_prostate_resections_ehr.condition_occurrence_id;

--fillyjonk
DROP TABLE IF EXISTS closest_bladder_biopsies_tumor_registry;
CREATE TABLE closest_bladder_biopsies_tumor_registry(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_bladder_biopsies_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_registry_diagnosis_date
)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date_abs
      , data.closest_biopsy_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(bladder_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date) AS closest_biopsy_date_minus_registry_diagnosis_date_abs
        , bladder_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date AS closest_biopsy_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN bladder_biopsies ON tumor_registry_diagnoses.person_id = bladder_biopsies.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_bladder_biopsy_date_minus_registry_diagnosis_date = closest_bladder_biopsies_tumor_registry.closest_biopsy_date_minus_registry_diagnosis_date
FROM closest_bladder_biopsies_tumor_registry
WHERE patients.person_id = closest_bladder_biopsies_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_bladder_biopsies_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_bladder_biopsies_ehr;
CREATE TABLE closest_bladder_biopsies_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_ehr_diagnosis_date        BIGINT       NULL
);


INSERT INTO closest_bladder_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(bladder_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date) AS closest_biopsy_date_minus_ehr_diagnosis_date_abs
        , bladder_biopsies.biopsy_date - prostate_clinical_diagnoses.diagnosis_start_date AS closest_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN bladder_biopsies           ON tumor_registry_diagnoses.person_id = bladder_biopsies.person_id
                              JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_bladder_biopsy_date_minus_ehr_diagnosis_date = closest_bladder_biopsies_ehr.closest_biopsy_date_minus_ehr_diagnosis_date
FROM closest_bladder_biopsies_ehr
WHERE patients.person_id = closest_bladder_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_bladder_biopsies_ehr.condition_occurrence_id;

DROP TABLE IF EXISTS closest_bladder_resections_tumor_registry;
CREATE TABLE closest_bladder_resections_tumor_registry(
  person_id                                              BIGINT       NULL,
  condition_occurrence_id                                BIGINT       NULL,
  closest_resection_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_bladder_resections_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_registry_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date_abs
      , data.closest_resection_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(bladder_resections.resection_date - tumor_registry_diagnoses.condition_start_date) AS closest_resection_date_minus_registry_diagnosis_date_abs
        , bladder_resections.resection_date - tumor_registry_diagnoses.condition_start_date AS closest_resection_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN bladder_resections ON tumor_registry_diagnoses.person_id = bladder_resections.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_bladder_resection_date_minus_registry_diagnosis_date = closest_bladder_resections_tumor_registry.closest_resection_date_minus_registry_diagnosis_date
FROM closest_bladder_resections_tumor_registry
WHERE patients.person_id = closest_bladder_resections_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_bladder_resections_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_bladder_resections_ehr;
CREATE TABLE closest_bladder_resections_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_resection_date_minus_ehr_diagnosis_date     BIGINT       NULL
);

INSERT INTO closest_bladder_resections_ehr
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date_abs
      , data.closest_resection_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(bladder_resections.resection_date - prostate_clinical_diagnoses.diagnosis_start_date) AS closest_resection_date_minus_ehr_diagnosis_date_abs
        , bladder_resections.resection_date - prostate_clinical_diagnoses.diagnosis_start_date AS closest_resection_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN bladder_resections         ON tumor_registry_diagnoses.person_id = bladder_resections.person_id
                              JOIN prostate_clinical_diagnoses ON tumor_registry_diagnoses.person_id = prostate_clinical_diagnoses.person_id
WHERE cancer_type = 'Prostate'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_bladder_resection_date_minus_ehr_diagnosis_date = closest_bladder_resections_ehr.closest_resection_date_minus_ehr_diagnosis_date
FROM closest_bladder_resections_ehr
WHERE patients.person_id = closest_bladder_resections_ehr.person_id
AND patients.condition_occurrence_id = closest_bladder_resections_ehr.condition_occurrence_id;
--fillyjonk

DROP TABLE IF EXISTS closest_pancreas_biopsies_tumor_registry;
CREATE TABLE closest_pancreas_biopsies_tumor_registry(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_pancreas_biopsies_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_registry_diagnosis_date
)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_registry_diagnosis_date_abs
      , data.closest_biopsy_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(pancreas_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date) AS closest_biopsy_date_minus_registry_diagnosis_date_abs
        , pancreas_biopsies.biopsy_date - tumor_registry_diagnoses.condition_start_date AS closest_biopsy_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN pancreas_biopsies ON tumor_registry_diagnoses.person_id = pancreas_biopsies.person_id
WHERE cancer_type = 'Pancreas'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_registry_diagnosis_date = closest_pancreas_biopsies_tumor_registry.closest_biopsy_date_minus_registry_diagnosis_date
FROM closest_pancreas_biopsies_tumor_registry
WHERE patients.person_id = closest_pancreas_biopsies_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_pancreas_biopsies_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_pancreas_biopsies_ehr;
CREATE TABLE closest_pancreas_biopsies_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_biopsy_date_minus_ehr_diagnosis_date        BIGINT       NULL
);

INSERT INTO closest_pancreas_biopsies_ehr
(
  person_id
, condition_occurrence_id
, closest_biopsy_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_biopsy_date_minus_ehr_diagnosis_date_abs
      , data.closest_biopsy_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_biopsy_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(pancreas_biopsies.biopsy_date - pancreas_clinical_diagnoses.diagnosis_start_date) AS closest_biopsy_date_minus_ehr_diagnosis_date_abs
        , pancreas_biopsies.biopsy_date - pancreas_clinical_diagnoses.diagnosis_start_date AS closest_biopsy_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN pancreas_biopsies           ON tumor_registry_diagnoses.person_id = pancreas_biopsies.person_id
                              JOIN pancreas_clinical_diagnoses ON tumor_registry_diagnoses.person_id = pancreas_clinical_diagnoses.person_id
WHERE cancer_type = 'Pancreas'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_biopsy_date_minus_ehr_diagnosis_date = closest_pancreas_biopsies_ehr.closest_biopsy_date_minus_ehr_diagnosis_date
FROM closest_pancreas_biopsies_ehr
WHERE patients.person_id = closest_pancreas_biopsies_ehr.person_id
AND patients.condition_occurrence_id = closest_pancreas_biopsies_ehr.condition_occurrence_id;

DROP TABLE IF EXISTS closest_pancreas_resections_tumor_registry;
CREATE TABLE closest_pancreas_resections_tumor_registry(
  person_id                                              BIGINT       NULL,
  condition_occurrence_id                                BIGINT       NULL,
  closest_resection_date_minus_registry_diagnosis_date   BIGINT       NULL
);

INSERT INTO closest_pancreas_resections_tumor_registry
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_registry_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_registry_diagnosis_date_abs
      , data.closest_resection_date_minus_registry_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_registry_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(pancreas_resections.resection_date - tumor_registry_diagnoses.condition_start_date) AS closest_resection_date_minus_registry_diagnosis_date_abs
        , pancreas_resections.resection_date - tumor_registry_diagnoses.condition_start_date AS closest_resection_date_minus_registry_diagnosis_date
FROM tumor_registry_diagnoses JOIN pancreas_resections ON tumor_registry_diagnoses.person_id = pancreas_resections.person_id
WHERE cancer_type = 'Pancreas'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_registry_diagnosis_date = closest_pancreas_resections_tumor_registry.closest_resection_date_minus_registry_diagnosis_date
FROM closest_pancreas_resections_tumor_registry
WHERE patients.person_id = closest_pancreas_resections_tumor_registry.person_id
AND patients.condition_occurrence_id = closest_pancreas_resections_tumor_registry.condition_occurrence_id;

DROP TABLE IF EXISTS closest_pancreas_resections_ehr;
CREATE TABLE closest_pancreas_resections_ehr(
  person_id                                           BIGINT       NULL,
  condition_occurrence_id                             BIGINT       NULL,
  closest_resection_date_minus_ehr_diagnosis_date     BIGINT       NULL
);

INSERT INTO closest_pancreas_resections_ehr
(
  person_id
, condition_occurrence_id
, closest_resection_date_minus_ehr_diagnosis_date

)
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date
FROM
(
SELECT  data.person_id
      , data.condition_occurrence_id
      , data.closest_resection_date_minus_ehr_diagnosis_date_abs
      , data.closest_resection_date_minus_ehr_diagnosis_date
      , row_number() over(partition by data.person_id, data.condition_occurrence_id ORDER BY data.closest_resection_date_minus_ehr_diagnosis_date_abs ASC) AS rn
FROM(
SELECT    tumor_registry_diagnoses.person_id
        , tumor_registry_diagnoses.condition_occurrence_id
        , ABS(pancreas_resections.resection_date - pancreas_clinical_diagnoses.diagnosis_start_date) AS closest_resection_date_minus_ehr_diagnosis_date_abs
        , pancreas_resections.resection_date - pancreas_clinical_diagnoses.diagnosis_start_date AS closest_resection_date_minus_ehr_diagnosis_date
FROM tumor_registry_diagnoses JOIN pancreas_resections         ON tumor_registry_diagnoses.person_id = pancreas_resections.person_id
                              JOIN pancreas_clinical_diagnoses ON tumor_registry_diagnoses.person_id = pancreas_clinical_diagnoses.person_id
WHERE cancer_type = 'Pancreas'
) data
) data
WHERE data.rn = 1
ORDER BY data.person_id, data.rn;

UPDATE patients
SET closest_resection_date_minus_ehr_diagnosis_date = closest_pancreas_resections_ehr.closest_resection_date_minus_ehr_diagnosis_date
FROM closest_pancreas_resections_ehr
WHERE patients.person_id = closest_pancreas_resections_ehr.person_id
AND patients.condition_occurrence_id = closest_pancreas_resections_ehr.condition_occurrence_id;


DROP TABLE IF EXISTS first_breast_clinical_diagnoses;
CREATE TABLE first_breast_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date,
  rn                            BIGINT
);

INSERT INTO first_breast_clinical_diagnoses
(
    person_id
  , diagnosis_start_date
  , rn

)
SELECT  person_id
      , condition_start_date
      , rn
FROM(
SELECT  person_id
      , row_number() over(partition by data.person_id ORDER BY data.condition_start_date ASC) AS rn
      , condition_start_date
FROM(
SELECT DISTINCT condition_occurrence.person_id
              , condition_occurrence.condition_start_date
FROM condition_occurrence JOIN breast_concepts ON condition_occurrence.condition_concept_id = breast_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
) data
) data2
WHERE data2.rn IN(1,2)
ORDER BY person_id, rn;

UPDATE patients
SET second_ehr_diagnosis_date = first_breast_clinical_diagnoses.diagnosis_start_date
FROM first_breast_clinical_diagnoses
WHERE first_breast_clinical_diagnoses.person_id = patients.person_id
AND patients.cancer_type = 'Breast'
AND first_breast_clinical_diagnoses.rn = 2;


DROP TABLE IF EXISTS first_prostate_clinical_diagnoses;
CREATE TABLE first_prostate_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date,
  rn                            BIGINT
);

INSERT INTO first_prostate_clinical_diagnoses
(
    person_id
  , diagnosis_start_date
  , rn

)
SELECT  person_id
      , condition_start_date
      , rn
FROM(
SELECT  person_id
      , row_number() over(partition by data.person_id ORDER BY data.condition_start_date ASC) AS rn
      , condition_start_date
FROM(
SELECT DISTINCT condition_occurrence.person_id
              , condition_occurrence.condition_start_date
FROM condition_occurrence JOIN prostate_concepts ON condition_occurrence.condition_concept_id = prostate_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
) data
) data2
WHERE data2.rn IN(1,2)
ORDER BY person_id, rn;

UPDATE patients
SET second_ehr_diagnosis_date = first_prostate_clinical_diagnoses.diagnosis_start_date
FROM first_prostate_clinical_diagnoses
WHERE first_prostate_clinical_diagnoses.person_id = patients.person_id
AND patients.cancer_type = 'Prostate'
AND first_prostate_clinical_diagnoses.rn = 2;

DROP TABLE IF EXISTS first_pancreas_clinical_diagnoses;
CREATE TABLE first_pancreas_clinical_diagnoses(
  person_id                     BIGINT,
  diagnosis_start_date          date,
  rn                            BIGINT
);

INSERT INTO first_pancreas_clinical_diagnoses
(
    person_id
  , diagnosis_start_date
  , rn

)
SELECT  person_id
      , condition_start_date
      , rn
FROM(
SELECT  person_id
      , row_number() over(partition by data.person_id ORDER BY data.condition_start_date ASC) AS rn
      , condition_start_date
FROM(
SELECT DISTINCT condition_occurrence.person_id
              , condition_occurrence.condition_start_date
FROM condition_occurrence JOIN pancreas_concepts ON condition_occurrence.condition_concept_id = pancreas_concepts.concept_id
WHERE condition_occurrence.condition_type_concept_id = 32817 --EHR
) data
) data2
WHERE data2.rn IN(1,2)
ORDER BY person_id, rn;

UPDATE patients
SET second_ehr_diagnosis_date = first_pancreas_clinical_diagnoses.diagnosis_start_date
FROM first_pancreas_clinical_diagnoses
WHERE first_pancreas_clinical_diagnoses.person_id = patients.person_id
AND patients.cancer_type = 'Pancreas'
AND first_pancreas_clinical_diagnoses.rn = 2;

UPDATE patients
SET second_ehr_diagnosis_date_minus_first_ehr_diagnosis_date = second_ehr_diagnosis_date - ehr_diagnosis_date;

SELECT  cancer_type
      -- , patients.person_id
      , row_number() over(ORDER BY patients.person_id desc) AS deidentified_person_id
      , registry_diagnosis_date_minus_ehr_diagnosis_date
      , closest_biopsy_date_minus_registry_diagnosis_date
      , closest_biopsy_date_minus_ehr_diagnosis_date
      , closest_resection_date_minus_registry_diagnosis_date
      , closest_resection_date_minus_ehr_diagnosis_date
      , closest_outside_biopsy_date_minus_registry_diagnosis_date
      , closest_outside_biopsy_date_minus_ehr_diagnosis_date
      , second_ehr_diagnosis_date_minus_first_ehr_diagnosis_date
      --prostate only
      , closest_bladder_biopsy_date_minus_registry_diagnosis_date
      , closest_bladder_biopsy_date_minus_ehr_diagnosis_date
      , closest_bladder_resection_date_minus_registry_diagnosis_date
      , closest_bladder_resection_date_minus_ehr_diagnosis_date
FROM patients;



--
-- select  c1.concept_id
--      , c1.concept_name
--      , c2.concept_name
--      , c2.concept_id
--      , c2.vocabulary_id
-- from concept c1 join concept_ancestor ca1 on c1.concept_id = ca1.ancestor_concept_id
--                join concept c2 on ca1.descendant_concept_id = c2.concept_id
-- -- where c1.concept_id = 4311405   --Biopsy
-- -- where c1.concept_id = 4213297   --Surgical pathology procedure
-- -- where c1.concept_id = 4278515   --Biopsy of prostate
-- -- where c1.concept_id = 4047494   --Biopsy of breast
-- -- where c1.concept_id = 4138981   --Biopsy of pancreas
-- -- where c1.concept_id = 4267975   --Biopsy of bladder
-- -- where c1.concept_id = 4235738   --Prostatectomy
-- -- where c1.concept_id = 4286804   --Excision of breast tissue
-- -- where c1.concept_id = 4141456   --Pancreatectomy
-- -- where c1.concept_id = 4029571   --Bladder excision
-- -- where c1.concept_id in(
-- -- 4244107   --Surgical pathology consultation and report on referred slides prepared elsewhere
-- -- , 2213294 --Consultation, comprehensive, with review of records and specimens, with report on referred material
-- -- )
-- order by c2.vocabulary_id, c2.concept_name