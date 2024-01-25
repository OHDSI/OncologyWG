# Oncology Validation Framework

## Purpose

Provide a semi-automated and extensible framework for generating, visualizing, and sharing an assessment of an OMOP-shaped database's adherence to the OHDSI Oncology Standard (tables, vocabulary) and the availabilty and types of oncology data it contains.

## Overview

The star of the framework is an R Package. Along with cataloguing an extensible set of queries and analyses used for assessing OMOP-shaped oncology data, the R package provides functionality for the four major processes involved in the framework:

1) Authoring an assessment specification
2) Executing an assessment specification
3) Generating assessment results
4) Visualizing assessment results

### Approach

_Assessments_ can be executed against an OMOP-shaped database to create a characterization and quality report. They are created using specificications. 

_Specifications_ are JSON files that describe an assessment. They are composed by compiling analyses together with threshhold values. 

_Analyses_ execute a query and return a row count or proportion describing the contents in the database. For example, analysis_id=1234 returns "the number of cancer diagnosis records derived from Tumor Registry source data".

_Threshholds_ provide study specific context to the results of analyses. An analysis asks how many cancer diagnoses derived from tumor registry data are in the database. Using threshholds, an assessment author can give ranges for "bad", "questionable", and "good" analysis results as they pertain to their study. An example threshhold, which would be encoded as JSON, could express the sentiment "A database with 0-200 diagnoses from tumor registry data would be unfit for this study, 201-500 diagnoses may be suitable, and over 500 diagnoses will be more enough."

## Contributing

Like the the OHDSI Oncology Module, the Oncology Validation Framework is a _work in progress_ and is built to be extensible. The framework was designed with the philosophy that as development finishes on a given Oncology Module convention (such as handling of TNM values or metastases), the validation framework would be extended so that an OMOP database's __adherence to that convention could be validated__ and the Oncology-related __content of database could be characterized__. In context of the [Oncology Maturity Sprint](https://github.com/orgs/OHDSI/projects/13/views/2), where "Task Groups" are used to organize all of the work that needs to be done for a specific oncology convention, creating new analyses for the framework fits squarely into the "Validate and ingest" component.

The following walkthrough demonstrates how analyses can be created and contributed to extend the Oncology Validation Framework to cover a newly finished convention.