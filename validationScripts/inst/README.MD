# Oncology Validation Framework: Analyses and Queries

## Overview
The analyses in the Oncology Validation Framework are meant to be extensible. Practically, this means that OncologyWG developers should be able to create these analyses to support the quality control needs of specific studies and study authors. This document outlines how analyses and queries are managed in this directory. Further, it explains how analyses are built from queries and demonstrates how to do this with examples.

## Definitions

Definitions for the major terms to know

### Queries

Queries are the most granular unit of measure. The result of an individual query is a distinct new table inserted into the "scratch database schema" with one or more variables (columns). These query tables are then summarized by analyses.

### Analyses

Analyses are the unit of measure that are used in assessments. The results of analyses, which summarize the information in the query results tables, are rows added to the validation results table.

All analyses have dependencies. Analyses can depend on one or more queries or analyses. These dependencies are recorded in the __queries__ and __composite_analyses__ fields of the __onc_analyses.json__ file.

## Directory Structure

### csv 

This directory contains any csv files that will be used by the R Package. Notably, it contains the __onc_queries.csv__ file that lists all query ids, their names, and other query information such as category.

### json

This directory contains any json files that will be used by the R Package. Notably, it contains the __onc_analyses.json__ file that lists all analyses ids, their names, and other analysis information such as dependencies.

### sql

This directory contains SQL scripts that are excuted from the R Package. SQL scripts are parameterized and executed using the SqlRender R Package. The SQL directory contains subdirectories __queries__ and __composite_analyses__ which contain the scripts for queries and analyses as recorded in __onc_queries.csv__ and __onc_analyses.json__, respectively. Each of these subdirectories also has an insert helper script. A thrid subdirectory, __spark__, contains Apache Spark-specific SQL scripts that are used by SqlRender. This directory also contains the DDL scripts for results tables.
