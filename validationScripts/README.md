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

> __Prerequisite:__ Make sure to see the README of the [_validationScripts/inst_](https://github.com/OHDSI/OncologyWG/tree/master/validationScripts/inst) directory which gives an overview of data management for the framework and defines some key terms.

### Planning

Before creating the analyses, it's a good idea to plan your approach:

#### Choose an Oncology Convention

Choose the Oncology Convention that you plan to validate and limit yourself to that scope. Not only will this make your development process more cohesive, but will also be easier for others to review your Pull Request if the analyses only concern one domain.

The big exception here is that you may find that you need to create "general" analyses or queries to support the analyses within your scope. For example, if you are interested in creating an analysis for a _proportion_, you will necessarily need to use two _count_ values. If you are looking for the _proportion_ of cancer diagnosis records with an associated stage group value, this could be done with two queries: one would be the _count_ of all Stage Group records (squarely within the scope of "Stage Group"), and the other would be the _count_ all cancer diagnosis records (which would be a "General" query).

Choose an Oncology Convention that your work depends on, create validation analyses for that convention, and then create a Pull Request.

#### List analysis requirements

What features of the Oncology Convention would a study author be concerned by? Try to create a comprehensive list of all of the _quality_ and _characterization_ analyses that would be useful or of interest to a study author assessing a database's fitness for use. When drafting this list, remember to think of analyses in terms of _counts_ and _proportions_, such as "the number of cancer records that come from a tumor registry source".

When thinking about database _quality_, analyses could be built around common mistakes in the ETL process, use of non-standard concepts, or logical impossiblities. For example, analyses for "Date of Initial Diagnosis" quality could address simple logical impossibilities such as the date of diagnosis occurring before the patient's birthdate or after their death. They could validate that each cancer diagnosis in the database has exactly one "date of initial diagnosis" record associated with it. These questions could be answered using analyses such as "the number of date of initial diagnosis records with impossible dates" and "the proportion of cancer diagnosis records with exactly one date of initial diagnosis record".

When thinking about database _characterization_, analyses could be built to explore the sources of data, and the values of the data themselves. For example, analyses to characterize TNM in a database could explore the breakdown of where data comes from (registry, EHR, etc.) or how many cancer diagnoses have associated metastases. In terms of building analyses, these could be phrased as "the proportion of TNM records by data source" and "the number of TNM records with metastases".

After you choose the scope of analyses to develop, try to create a plain-text list of all of the quality and characterization analyses that would be useful to a study author. The list may grow or change as you start translating them to SQL, but having a solid list to work from will make later steps clearer.

> Note: This list of analyses will eventually become part of the onc_analyses.json file which contains names, ids, and other high-level information about analyses. 

#### Translate your list into SQL scripts

> __Prerequisite:__ It would be good to have a basic understanding of [SqlRender](https://ohdsi.github.io/SqlRender/articles/UsingSqlRender.html)

##### Background

When creating SQL scripts for your analyses, its important to recall the interplay between what we call __analyses__ and __queries__, as described in the README of the [_validationScripts/inst_](https://github.com/OHDSI/OncologyWG/tree/master/validationScripts/inst) directory. In short, queries create distinct tables and can be any shape; queries are the building blocks to analyses. Analyses piece together one or more query tables and summarize them as a single row in the results table.

The simplest query-analysis instance is one query that creates a table of all record ids, and analysis that counts all records in this table and returns that count value. An example of this is __analysis 2__: "Number of cancer diagnoses":

```sql
-- 2  Number of cancer diagnoses

select 2 as analysis_id,  
cast(null as varchar(255)) as stratum_1, cast(null as varchar(255)) as stratum_2, cast(null as varchar(255)) as stratum_3, cast(null as varchar(255)) as stratum_4, cast(null as varchar(255)) as stratum_5,
COUNT_BIG(*) as count_value
FROM @scratchDatabaseSchema.onc_val_general_2
```

All this script does is count the rows in the table `onc_val_general_2`. This table is created by __query 2__: "Condition_occurrence_ids of cancer diagnoses":

```sql
-- 2  Condition_occurrence_ids of cancer diagnoses

SELECT co.condition_occurrence_id
FROM @cdmDatabaseSchema.condition_occurrence co
INNER JOIN (
    SELECT DISTINCT concept_id 
    FROM (
        SELECT c.concept_id
        FROM  @vocabDatabaseSchema.concept c
        INNER JOIN @vocabDatabaseSchema.concept_ancestor ca
        ON c.concept_id = ca.descendant_concept_id
        AND ca.ancestor_concept_id = 438112 -- neoplastic disease

        UNION ALL

        SELECT concept_id
        FROM @vocabDatabaseSchema.concept 
        WHERE concept_class_id = 'ICDO Condition' 
    )
) dcc
ON co.condition_concept_id = dcc.concept_id
```

The inner query gets all concept_ids that would indicate a cancer condition and then does a filtering join to the condition_occurrence table to get all cancer diagnosis records. 

How are these SQL scripts linked together? As is clear above, the _analysis_ refers to a table that is created by the _query_. To go a bit deeper, they are also linked in the onc_analyses.json file that contains analyses metadata:

```json
{
    "analysis_id": "2",
    "analysis_name": "Number of cancer diagnoses", 
    "analysis_type": "count", 
    "queries": [2],
    "composite_analyses": []
}
```

This linkage in the metadata is important because it allows the R Package, which is orchestrating these SQL scripts, to know that analysis 2 __depends on__ query 2. Since we're talking about metadata, we can also peek at the onc_queries.csv file to see what query 2 metadata looks like:

| query_id | distribution | distributed_field | query_name                                   | stratum_1_name | stratum_2_name | stratum_3_name | stratum_4_name | stratum_5_name | is_default | category |
|----------|--------------|-------------------|----------------------------------------------|----------------|----------------|----------------|----------------|----------------|------------|----------|
|        2 |            0 |                   | Condition_occurrence_ids of cancer diagnoses |                |                |                |                |                |          1 | General  |

Notably, this table contains the query_id and the category which are both used to create the table name where the query results are stored. Also good to note that the query does not explicitly link to analyses.

##### Putting it all together

Now we've seen the elements of analysis:
1. Analysis SQL script (stored in `inst/sql/composite_analyses/<analysis_id>.sql`)
1. A metadata entry in `inst/json/onc_analyses.json`
1. Query SQL script (one or more, stored in `inst/sql/queries/<query_id>.sql`)
1. A metadata entry in `inst/csv/onc_queries.csv`
>You will _always_ need to create a new analysis SQL script and metadata entry for analyses that you create. If your new analysis depends on queries that already exist, then you don't actually need to create or alter query scripts or metadata.

<!-- Analysis 15 example: start by building query, mention group by and strata -->

<!-- Analysis 150 example: referencing analysis 15  -->

<!-- Analysis 1001 example: multiple query dependencies -->

<!-- Analysis 1002 example: proporting -->