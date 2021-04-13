The VISIT_OCCURRENCE table contains the spans of time a Person continuously receives medical services from one or more providers at a Care Site in a given setting within the health care system. Visits are classified into 4 settings: outpatient care, inpatient confinement, emergency room, and long-term care. Persons may transition between these settings over the course of an episode of care (for example, treatment of a disease onset). 

Field|Required|Type|Description
:------------------------|:--------|:-----|:-------------------------------------------------
|visit_occurrence_id|Yes|integer|A unique identifier for each Person's visit or encounter at a healthcare provider.|
|person_id|Yes|integer|A foreign key identifier to the Person for whom the visit is recorded. The demographic details of that Person are stored in the PERSON table.|
|visit_concept_id|Yes|integer|A foreign key that refers to a visit Concept identifier in the Standardized Vocabularies belonging to the 'Visit' Vocabulary.|
|visit_start_date|No|date|The start date of the visit.|
|visit_start_datetime|Yes|datetime|The date and time of the visit started.|
|visit_end_date|No|date|The end date of the visit. If this is a one-day visit the end date should match the start date.|
|visit_end_datetime|Yes|datetime|The date and time of the visit end.|
|visit_type_concept_id|Yes|Integer|A foreign key to the predefined Concept identifier in the Standardized Vocabularies reflecting the type of source data from which the visit record is derived belonging to the 'Visit Type' vocabulary.|
|provider_id|No|integer|A foreign key to the provider in the provider table who was associated with the visit.|
|care_site_id|No|integer|A foreign key to the care site in the care site table that was visited.|
|visit_source_value|No|varchar(50)|The source code for the visit as it appears in the source data.|
|visit_source_concept_id|Yes|integer|A foreign key to a Concept that refers to the code used in the source.|
|admitting_source_concept_id	|Yes	|integer	|A foreign key to the predefined concept in the Place of Service Vocabulary reflecting the admitting source for a visit.|
|admitting_source_value			|	No|varchar(50)|	The source code for the admitting source as it appears in the source data.|
|discharge_to_concept_id		|Yes	|	integer	|A foreign key to the predefined concept in the Place of Service Vocabulary reflecting the discharge disposition for a visit.|
|discharge_to_source_value		|	No|	varchar(50)|	The source code for the discharge disposition as it appears in the source data.|
|preceding_visit_occurrence_id	|	No	|integer|A foreign key to the VISIT_OCCURRENCE table of the visit immediately preceding this visit|

### Conventions 

No.|Convention Description
:--------|:------------------------------------   
| 1  | A Visit Occurrence is recorded for each visit to a healthcare facility. |
| 2  | Valid Visit Concepts belong to the 'Visit' domain. |
| 3  | Standard Visit Concepts are defined, among others, as Inpatient Visit, Outpatient Visit, Emergency Room Visit, Long Term Care Visit and combined ER and Inpatient Visit. The latter is necessary because it is close to impossible to separate the two in many EHR system, treating them interchangeably. To annotate this correctly, the visit concept 'Emergency Room and Inpatient Visit' (concept_id=262) should be used.
| 4  | Handling of death: In the case when a patient died during admission (VISIT_OCCURRENCE.DISCHARGE_TO_CONCEPT_ID = 4216643 'Patient died'), a record in the Observation table should be created with OBSERVATION_TYPE_CONCEPT_ID = 44818516 (EHR discharge status 'Expired').|
| 5  | Source Concepts from place of service vocabularies are mapped into these standard visit Concepts in the Standardized Vocabularies. |
| 6  | At any one day, there could be more than one visit. |
| 7  | One visit may involve multiple providers, in which case the ETL must specify how a single PROVIDER_ID is selected or leave the PROVIDER_ID field null. |
| 8  | One visit may involve multiple Care Sites, in which case the ETL must specify how a single CARE_SITE_ID is selected or leave the CARE_SITE_ID field null.
| 9  | Visits are recorded in various data sources in different forms with varying levels of standardization. For example:<br><ul><li>Medical Claims include Inpatient Admissions, Outpatient Services, and Emergency Room visits.</li><li>Electronic Health Records may capture Person visits as part of the activities recorded depending whether the EHR system is used at the different Care Sites./li></ul> |
| 10 | In addition to the 'Place of Service' vocabulary the following SNOMED concepts for discharge disposition (DISCHARGE_TO_CONCEPT_ID) can be used:<br><ul><li>Patient died: 4216643</li><li>Absent without leave: 44814693</li><li>Patient self-discharge against medical advice: 4021968</li></ul> |
| 11 | PRECEDING_VISIT_ID can be used to link a visit immediately preceding the current visit. |
| 12 | Visit end dates are mandatory. If end dates are not provided in the source there are three ways in which to derive them:<br><ul><li>Outpatient Visit: VISIT_END_DATE = VISIT_START_DATE</li><li>Emergency Room Visit: VISIT_END_DATE = VISIT_START_DATE</li><li>Inpatient Visit: Usually there is information about discharge. If not, you should be able to derive the end date from the sudden decline of activity or from the absence of inpatient procedures/drugs.</li><li>Long Term Care Visits: Particularly for claims data, if end dates are not provided assume the visit is for the duration of month that it occurs.</li><li>For inpatient visits ongoing at the date of ETL, put date of processing the data as mandatory VISIT_END_DATE and VISIT_TYPE_CONCEPT_ID with 32220-"Still patient" to identify the visit as incomplete.</li></ul>([THEMIS issue #13](https://github.com/OHDSI/Themis/issues/13)).|
