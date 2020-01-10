---
output:
  html_document: default
  pdf_document: default
---
NaaccrParser
------------

<!-- badges: start -->
<!-- badges: end -->

This package ingests NAACCR fixed width format files (v15, v16, v18), converts the data into a parsable format, and ingests it into a database. This is meant to be the first step of an [ETL process](https://github.com/OHDSI/OncologyWG/wiki/NAACCR-ETL) by the OHDSI Oncology WG to translate NAACCR data into OHDSI CDM tables. This package transforms the source data into an [intermediate format](https://github.com/OHDSI/OncologyWG/wiki/NAACCR-ETL/ETL/NAACCR-ETL/naaccr_data_points), similar to an EAV structure. 


## Installation

You can install the package by downloading the zip directly from  [Github](https://github.com/OHDSI/OncologyWG/tree/master/NaaccrParser) or install the package from R:

``` r
install.packages("devtools")
devtools::install_github("OHDSI/OncologyWG", subdir="NaaccrParser")
```

## Getting started
Load package

``` r
library(NaaccrParser)

```
As we are splitting up rows into an EAV structure, we need to retain provenance by appending a source row index to each value pair. The record id prefix is intended to be unique to each file and will be concatenated to the front of each row index. The record id is only used a means to complete the ETL and is not retained in the destination data. 

```r
record_id_prefix <- "my_id_prefix"

```

Create connection details to your CDM database using the [Database Connector](https://github.com/OHDSI/DatabaseConnector) package.

```r
connectionDetails <- createConnectionDetails(
  dbms="sql server",
  server="",
  user="",
  password="",
  schema ="NAACCR.dbo"
)

```

Call the main function to ingest the data 
```r
# Import data  into database
NAACCR_to_db(file_path = "path_to_data/naaccr_file.csv"
             , record_id_prefix = record_id_prefix
             , connectionDetails = connectionDetails)
```

At this point the data exists in your database without person_id assigned. This step is optiona as this process can vary between institutions. To populate person_id using this function, you need to create a table in your database that maps MRN to person_id. If the mapping table has a different field name for MRN other than "MRN", it must be specified used the 'person_map_field' parameter. 

```r
assign_person_id(connectionDetails = connectionDetails
                 ,person_map_table = "thisdb.dbo.person_map_table"
                 ,person_map_field = "MRN")

```
