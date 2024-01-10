NaaccrParser
------------

<!-- badges: start -->
<!-- badges: end -->

This package ingests NAACCR formatted source files, converts the data into a parsable format, and ingests it into a database. This is meant to be the first step of an [ETL process](https://github.com/OHDSI/OncologyWG/wiki/NAACCR-ETL) by the OHDSI Oncology WG to translate NAACCR data into OHDSI CDM tables. This package transforms the source data into an [intermediate format](https://github.com/OHDSI/OncologyWG/wiki/NAACCR-ETL/ETL/NAACCR-ETL/naaccr_data_points), similar to an EAV structure. 

This package supports parsing of source files from both fixed width (v15, v16, v18) and XML format (v20-23) NAACCR standards. Once ingested into an EAV format, there is a vocabulary-driven ETL written in SQL to convert the data into OMOP.  

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
As we are splitting up rows into an EAV structure, we need to retain provenance by appending a source row index to each value pair. The record id prefix is intended to be unique to each file and will be concatenated to the front of each row index. The record id is only used a means to complete the ETL and is not retained in the destination data. If left NULL (which is fine), it uses the current file name as the prefix. 

```r
record_id_prefix <- "my_id_prefix"

```

Create connection details to your CDM database using the [Database Connector](https://github.com/OHDSI/DatabaseConnector) package.

```r
connectionDetails <- createConnectionDetails(
  dbms="sql server",
  server="",
  user="",
  password=""
)

```

There are separate functions for parsing and ingesting fixed-width source files (v16-18) as well as for XML formatted source files (v20+). If you have a collection of files in the same directory you can leverage an umbrella function that parses all files, regardless of version. 

### Option 1: (directory specific)

Parse and ingest **all NAACCR files within a specified directory**
```r
parse_directory(dir_path = dir_path # folder containing NAACCR files
                ,connectionDetails = connectionDetails)

```

That umbrella function calls helper functions that can be used called to parse individual files. This takes more time but can be used directly when more logical for a specific environment. 

### Option 2: (file specific)

Parse and ingest a **fixed-width file**:
```r
# Import data  into database
NAACCR_to_db(file_path = "path_to_data/naaccr_file.csv"
             , record_id_prefix = record_id_prefix  # optional
             , connectionDetails = connectionDetails)
```



Parse and ingest a **XML file**:
```r
# Import data  into database
parse_XML_to_DB(file_path = file_path
                ,record_id_prefix = NULL  # optional
                ,connectionDetails = connectionDetails)
```

### Populate person_id

At this point the data exists in your database without person_id assigned. This step is optiona as this process can vary between institutions. To populate person_id using this function, you need to create a table in your database that maps MRN to person_id. If the mapping table has a different field name for MRN other than "MRN", it must be specified used the 'person_map_field' parameter. 

```r
assign_person_id(connectionDetails = connectionDetails
                ,ndp_schema = 'NAACCR_OMOP.dbo'
                ,person_map_schema = 'OMOP_COMMON.dbo'
                ,person_map_table = 'person_map'
                ,person_map_field = "MRN")
```
