# Oncology Validation Framework

## Purpose

Provide a semi-automated and extensible framework for generating, visualizing, and sharing an assessment of an OMOP-shaped database's adherence to the OHDSI Oncology Standard (tables, vocabulary) and the availabilty and types of oncology data it contains.

## Overview

The star of the framework is an R Package. Along with cataloguing an extensible set of queries and analyses used for assessing OMOP-shaped oncology data, the R package provides functionality for the four major processes involved in the framework:

1) Authoring an assessment specification
2) Executing an assessment specification
3) Generating assessment results
4) Visualizing assessment results

## Analyses

### Classes of Analyses:

Analyses can be broken in to ____ different **classes**:

#### Meta checks

These analyses are very high-level and run at the very beginning of a validation test. If these tests fail, the user must correct them before the full analysis can be run.

##### Schema correctness
 - Do all relevant oncology-specific tables exist?
 - Do all relevant oncology-specific tables have the required column names?

##### Presence of development vocabulary
 - Does the vocabulary table contain the "Oncology development vocabulary" record, signifying that the user has added the Oncology development vocabulary?
    - If yes, is the version number the most recent Oncology development vocabulary version?

#### Existence of Any

These are analyses that check for the existence of anything unacceptable that must be changed

##### Incorrect or outdated concepts being used
 - Are any terms that have been destandardized by the Oncology development vocabulary being used?

#### Proportion of cancer patients

#### Proportion of Task group

#### Percentage of tests passed for each Task Group

#### Granularity of data

## Queries

Queries are the SQL counterpart to the analyses. Each analysis has a single query with which it is associated. The query lives in a sql file named `<analysis number>.sql` e.g. `1.sql`.

### Query Classes

The queries that are used for analyses fall into one of ___ classes:

#### Count of records by concept sets
 - Number of distinct concepts from the "correct" (standard) oncology concept set
 - Total number of concepts from the "correct" (standard) oncology concept set
 - Number of distinct concepts from the "incorrect" (newly destandardized/ non standard) oncology concept set
 - Total number of concepts from the "incorrect" (newly destandardized/ non standard) oncology concept set

#### Count of patients by concept sets
 - How many patients have records associated with the correct/incorrect concept set?

#### Referential integrity
 - Are modifier concepts associated with the correct types of records? E.g. are stage records modifying a cancer condition concept?


## Quality checks

Quality checks are captured as a series of parameterized SQL scripts that 

### Concept sets

For each "Task Group" for which we are checking quality, we start with the set of standard concepts that may be used for mapping. 

#### Option 1
These could be compiled in a style similar to the DQD concepts in a CSV:
`cdmTableName,cdmFieldName,conceptId,conceptName...,`

Where every table, field, and concept group are contained in the same table and are used to parameterize multiple different generic sql scripts.

A hard-coded list of all correct concepts and all incorrect concepts, in the same place

#### Option 2
Alternatively, one list of correct concepts for each "Task Group" could be maintained. To generate the list of incorrect concepts, simply query all non-standard concepts that map to the correct concepts. Along with being much easier to maintain (only need to create a list of correct/standard concepts), this would also allow us to provide suggestions on how to fix incorrect terms...



## List of Analyses:

| Task Groups | Check Set |
|-------------|-----------|
| Initial Date of Diagnosis | Simple |
| Specific Tumor Identifier | Simple |
| TNM | Full |
| Stage Group | Full |
| Grade | Full |
| Laterality | Full |
| Disease Progression | Full |
| Metastases | Full |
| Dimension | Full |
| Extension/Invasion | Full |
| Radiotherapy | Extended|
| Treatment Intent | Extended|
| Surgery | Extended|
| Drug Therapy | Extended|


---

| Type of Analysis | Check Set |
| How many records exist | Simple |
| How many records are "correct" | Simple |
| How many records are "incorrect" | Simple |
| How many patients have a record | Simple |





TNM Analyses (and Stage Group, Grade, lateratily, disease progression, Metastases, Dimension, Exten/Invsasion)
- How many rows are correct 
- How many patients have a correctly mapped TNM record (any record associated is correct)
- How many rows have a foreign key to a condition
- Proportion of rows correct
- Proportion of patients that have a correctly mapped TNM record over total number of patients with cancer diagnosis
- Proportion of rows have a foreign key to a condition
- How many rows are incorrect 
- How many patients are incorrect
- How many rows have incorrectly implemented FK (NULL or not to condition)

Initial Date of Diagnosis (specific tumor identifier)
- How many records exist (characterization)
- How many rows are correct (for in diagn, measurement_event_id points to a valid cancer diagnosis record in condition_occurrence, meas_event_field_concept_id is value 1147127 "condition_occurrence.concidtion_occurence_id")
- How many patients have a date of diagnosis record



Procedures (Radiotherapy, Treatment Intent, Surgery, Drug therapy)

Radiotherapy example:

Radiotherapy overview
- if coming from registry: maybe say type, subtype (brachytherapy), total dosage, but not at individual fraction level. Aggregated value of everything they have
- if coming from a stanadrard EHR, will include billing code only (some coarse type-site combo, see CPT codes)
- Oncology specific EMR (Mosaiq) will have everything that registry has but also the individual fraction level (individual "round" of radiotherapy)
- If coming from NLP or flowsheet parsing: as much or similar to onc-specific EMR data

Procedure Concept sets:
- High level radio therapy concepts
- Billing code radiotherapy concepts
- Low level radio therapy concepts

Modifier Concept sets
- Topography (correct and incorrect sets)
- Treatment intent
- Fractions (occurrences at individual occurrence level and at aggregated level)

Radiotherapy analyses

## How does DQD vs Achilles handle manage analyses

>TLDR; The checks in DQD are too general for what we are trying to do. Incorporating teh Cancer checks in their current form into DQD would require so much reworking of the DQD framework that it is unlikely the changes would ever get accepted back into a main branch.


### DQD 

There are 3 "levels" of checks TABLE FIELD and CONCEPT. The file inst/csv/OMOP_CDMv5.4_Check_Descriptions.csv lists all the checks, their level, name, description, Kahn class, the sqlFile that stores the check, and an "evaluationFilter"(?)



SQL scripts contain the "shells" of the analyses. CSV files contain the parameters for the SQL scripts.

Ex. concept_plausible_gender.sql takes a schema, table name, field name, concept ID, and the expected gender. The schema is passed from teh R function that executes. The rest are passed from the OMOP_CDMv5.4_Concept_Level.csv file which contains that information in a row that has a value in the column "plausibleGender".