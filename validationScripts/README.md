# Oncology Validation Framework

## Purpose

Provide a semi-automated and extensible framework for generating, visualizing, and sharing an assessment of an OMOP-shaped database's adherence to the OHDSI Oncology Standard (tables, vocabulary) and the availabilty and types of oncology data it contains.

## Overview

The star of the framework is an R Package. Along with cataloguing an extensible set of queries and analyses used for assessing OMOP-shaped oncology data, the R package provides functionality for the four major processes involved in the framework:

1) Authoring an assessment specification
2) Executing an assessment specification
3) Generating assessment results
4) Visualizing assessment results

_Assessments_ are created using specificications. _Specifications_ are composed by compiling analyses together with threshhold values. _Analyses_ return a number or proportion related to contents in the database. For example, analysis_id=1234 returns "the number of cancer diagnosis records derived from Tumor Registry source data". Threshholds 


