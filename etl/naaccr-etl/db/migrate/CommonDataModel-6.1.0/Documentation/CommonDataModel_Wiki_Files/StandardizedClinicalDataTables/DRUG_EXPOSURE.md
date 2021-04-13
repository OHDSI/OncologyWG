The 'Drug' domain captures records about the utilization of a Drug when ingested or otherwise introduced into the body. A Drug is a biochemical substance formulated in such a way that when administered to a Person it will exert a certain physiological effect. Drugs include prescription and over-the-counter medicines, vaccines, and large-molecule biologic therapies. Radiological devices ingested or applied locally do not count as Drugs.

Drug Exposure is inferred from clinical events associated with orders, prescriptions written, pharmacy dispensings, procedural administrations, and other patient-reported information, for example:

  * The 'Prescription' section of an EHR captures prescriptions written by physicians or from electronic ordering systems
  * The 'Medication list' section of an EHR for both non-prescription products and medications prescribed by other providers
  * Prescriptions filled at dispensing providers such as pharmacies, and then captured in reimbursement claim systems
  * Drugs administered as part of a Procedure, such as chemotherapy or vaccines.

Field|Required|Type|Description
:------------------------------|:--------|:------------|:------------------------------------------------
| drug_exposure_id				| Yes	| bigint	| A system-generated unique identifier for each Drug utilization event.                                                                                                            |
|person_id						|Yes	|bigint		|A foreign key identifier to the Person who is subjected to the Drug. The demographic details of that Person are stored in the PERSON table.                                      |
|drug_concept_id				|Yes	|integer	|A foreign key that refers to a Standard Concept identifier in the Standardized Vocabularies belonging to the 'Drug' domain.                                                      |
|drug_exposure_start_date		|No		|date		|The start date for the current instance of Drug utilization. Valid entries include a start date of a prescription, the date a prescription was filled, or the date on which a Drug administration procedure was recorded.|
|drug_exposure_start_datetime	|Yes	|datetime	|The start date and time for the current instance of Drug utilization. Valid entries include a start datetime of a prescription, the date and time a prescription was filled, or the date and time on which a Drug administration procedure was recorded.|
|drug_exposure_end_date			|No		|date		|The end date for the current instance of Drug utilization. Depending on different sources, it could be a known or an inferred date and denotes the last day at which the patient was still exposed to Drug.                                                                                 |
|drug_exposure_end_datetime		|No		|datetime	|The end date and time for the current instance of Drug utilization. Depending on different sources, it could be a known or an inferred date and time and denotes the last day at which the patient was still exposed to Drug.                                                                       |
|verbatim_end_date				|No		|date		|The known end date of a drug_exposure as provided by the source.                                                                                                                  |
|drug_type_concept_id			|Yes	|integer	| A foreign key to the predefined Concept identifier in the Standardized Vocabularies reflecting the type of Drug Exposure recorded. It indicates how the Drug Exposure was represented in the source data and belongs to the 'Drug Type' vocabulary.|
|stop_reason					|No		|varchar(20)|The reason the Drug was stopped. Reasons include regimen completed, changed, removed, etc.                                                                                       |
|refills						|No		|integer	|The number of refills after the initial prescription. The initial prescription is not counted, values start with null.                                                           |
|quantity 						|No		|float		|The quantity of drug as recorded in the original prescription or dispensing record.                                                                                              |
|days_supply					|No		|integer	|The number of days of supply of the medication as prescribed. This reflects the intention of the provider for the length of exposure.                                            |
|sig							|No		|varchar(MAX)|The directions ('signetur') on the Drug prescription as recorded in the original prescription (and printed on the container) or dispensing record.                              |
|route_concept_id				|Yes		|integer	|A foreign key that refers to a Standard Concept identifier in the Standardized Vocabularies reflecting the route of administration and belonging to the 'Route' domain.              |
|lot_number						|No		|varchar(50)|An identifier assigned to a particular quantity or lot of Drug product from the manufacturer.                                                                                     |
|provider_id					|No		|integer|A foreign key to the provider in the PROVIDER table who initiated (prescribed or administered) the Drug Exposure.|
|visit_occurrence_id			|No		|integer|A foreign key to the Visit in the VISIT_OCCURRENCE table during which the Drug Exposure was initiated.|
|visit_detail_id				|No		|integer|A foreign key to the Visit Detail in the VISIT_DETAIL table during which the Drug Exposure was initiated.|
|drug_source_value				|No		|varchar(50)|The source code for the Drug as it appears in the source data. This code is mapped to a Standard Drug concept in the Standardized Vocabularies and the original code is, stored here for reference.|
|drug_source_concept_id			|Yes		|integer|A foreign key to a Drug Concept that refers to the code used in the source.|
|route_source_value				|No		|varchar(50)|The information about the route of administration as detailed in the source.|
|dose_unit_source_value			|No		|varchar(50)|The information about the dose unit as detailed in the source.|

### Conventions 

No.|Convention Description
:--------|:------------------------------------ 
| 1  | Valid Concepts for the DRUG_CONCEPT_ID field belong to the 'Drug' domain. Most Concepts in the Drug domain are based on RxNorm, but some may come from other sources. Concepts are members of the Clinical Drug or Pack, Branded Drug or Pack, Drug Component or Ingredient classes. |
| 2  | Source drug identifiers, including NDC codes, Generic Product Identifiers, etc. are mapped to Standard Drug Concepts in the Standardized Vocabularies (e.g., based on RxNorm). When the Drug Source Value of the code cannot be translated into Standard Drug Concept IDs, a Drug exposure entry is stored with only the corresponding SOURCE_CONCEPT_ID and DRUG_SOURCE_VALUE and a DRUG_CONCEPT_ID of 0.
| 3  | The Drug Concept with the most detailed content of information is preferred during the mapping process. These are indicated in the CONCEPT_CLASS_ID field of the Concept and are recorded in the following order of precedence: 'Branded Pack', 'Clinical Pack', 'Branded Drug', 'Clinical Drug', 'Branded Drug Component', 'Clinical Drug Component', 'Branded Drug Form', 'Clinical Drug Form', and only if no other information is available 'Ingredient'. Note: If only the drug class is known, the DRUG_CONCEPT_ID field should contain 0.
| 4  | A Drug Type is assigned to each Drug Exposure to track from what source the information was drawn or inferred from. The valid CONCEPT_CLASS_ID for these Concepts is 'Drug Type'. |
| 5  | The content of the refills field determines the current number of refills, not the number of remaining refills. For example, for a drug prescription with 2 refills, the content of this field for the 3 Drug Exposure events are null, 1 and 2.|
| 6  | The ROUTE_CONCEPT_ID refers to a Standard Concepts of the 'Route' domain. Note: Route information can also be inferred from the Drug product itself by determining the Drug Form of the Concept, creating some partial overlap of the same type of information. Therefore, route information should be stored in DRUG_CONCEPT_ID (as a drug with corresponding Dose Form). The ROUTE_CONCEPT_ID could be used for storing more granular forms e.g. 'Intraventricular cardiac'.| 
| 7  | The LOT_NUMBER field contains an identifier assigned from the manufacturer of the Drug product. |
| 8  | If possible, the visit in which the drug was prescribed or delivered is recorded in the VISIT_OCCURRENCE_ID field through a reference to the visit table.|
| 9  | If possible, the prescribing or administering provider (physician or nurse) is recorded in the PROVIDER_ID field through a reference to the provider table.
| 10 | The DRUG_EXPOSURE_END_DATE denotes the day the drug exposure ended for the patient. This could be that the duration of DRUG_SUPPLY was reached (in which case DRUG_EXPOSURE_END_DATETIME = DRUG_EXPOSURE_START_DATETIME + DAYS_SUPPLY -1 day), or because the exposure was stopped (medication changed, medication discontinued, etc.)|
| 11 | When the native data suggests a drug exposure has a days supply less than 0, drop the record as unknown if a person has received the drug or not ([THEMIS issue #24](https://github.com/OHDSI/Themis/issues/24)).|
| 12 | If a patient has multiple records on the same day for the same drug or procedures the ETL should not de-dupe them unless there is probable reason to believe the item is a true data duplicate ([THEMIS issue #14](https://github.com/OHDSI/Themis/issues/14)).|
