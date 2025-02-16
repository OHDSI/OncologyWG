/*********************************************************************************
# Copyright 2014 Observational Health Data Sciences and Informatics
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
********************************************************************************/

/************************

 ####### #     # ####### ######      #####  ######  #     #           #######
 #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #
 #     # # # # # #     # #     #    #       #     # # # # #    #    # #
 #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######
 #     # #     # #     # #          #       #     # #     #    #    #       #
 #     # #     # #     # #          #     # #     # #     #     #  #  #     #
 ####### #     # ####### #           #####  ######  #     #      ##    #####


Script to load the common data model, version 5.0 vocabulary tables for SQL Server database

Notes

1) There is no data file load for the SOURCE_TO_CONCEPT_MAP table because that table is deprecated in CDM version 5.0
2) This script assumes the CDM version 5 vocabulary zip file has been unzipped into the "C:\CDMV5Vocabulary" directory.
3) If you unzipped your CDM version 5 vocabulary files into a different directory then replace all file paths below, with your directory path.
4) Run this SQL query script in the database where you created your CDM Version 5 tables

last revised: 26 Nov 2014

author:  Lee Evans


*************************/

TRUNCATE TABLE CONCEPT_NUMERIC;
BULK INSERT CONCEPT_NUMERIC
FROM 'C:\CDMV5VOCAB\CONCEPT_NUMERIC.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
ROWTERMINATOR = '0x0a',
ERRORFILE = 'C:\CDMV5VOCAB\CONCEPT_NUMERIC.bad',
TABLOCK
);
