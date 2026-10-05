REM *********************************************************************************
REM  Copyright 2014 Observational Health Data Sciences and Informatics
REM 
REM  
REM  Licensed under the Apache License, Version 2.0 (the "License");
REM  you may not use this file except in compliance with the License.
REM  You may obtain a copy of the License at
REM  
REM      http://www.apache.org/licenses/LICENSE-2.0
REM  
REM  Unless required by applicable law or agreed to in writing, software
REM  distributed under the License is distributed on an "AS IS" BASIS,
REM  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM  See the License for the specific language governing permissions and
REM  limitations under the License.
REM *******************************************************************************/

REM ************************
REM 
REM  ####### #     # ####### ######      #####  ######  #     #           ####### 
REM  #     # ##   ## #     # #     #    #     # #     # ##   ##    #    # #       
REM  #     # # # # # #     # #     #    #       #     # # # # #    #    # #       
REM  #     # #  #  # #     # ######     #       #     # #  #  #    #    # ######  
REM  #     # #     # #     # #          #       #     # #     #    #    #       # 
REM  #     # #     # #     # #          #     # #     # #     #     #  #  #     # 
REM  ####### #     # ####### #           #####  ######  #     #      ##    #####  
REM                                                                               
REM 
REM Script to load the common data model, version 5.0 vocabulary tables for PostgreSQL database on Windows (MS-DOS style file paths)
REM 
REM Notes
REM 
REM 1) There is no data file load for the SOURCE_TO_CONCEPT_MAP table because that table is deprecated in CDM version 5.0
REM 2) This script assumes the CDM version 5 vocabulary zip file has been unzipped into the "C:\CDMV5VOCAB" directory. 
REM 3) If you unzipped your CDM version 5 vocabulary files into a different directory then replace all file paths below, with your directory path.
REM 
REM last revised: 26 Nov 2014
REM 
REM author:  Lee Evans
REM 
REM revision: 19-NOV-2019
REM ensure the bat file is run from the same location as the data file i.e .csv files and the control files
REM for this specific for example 
REM E:\OncologyWG-master\OncologyWG-master\etl\naaccr-etl\db\migrate\CommonDataModel-5.3.1\Oracle\VocabImport
REM *************************/

sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT.ctl LOG=CONCEPT.log BAD=CONCEPT.bad  
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT_ANCESTOR.ctl LOG=CONCEPT_ANCESTOR.log BAD=CONCEPT_ANCESTOR.bad  
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT_CLASS.ctl LOG=CONCEPT_CLASS.log BAD=CONCEPT_CLASS.bad  
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT_RELATIONSHIP.ctl LOG=CCONCEPT_RELATIONSHIP.log BAD=CONCEPT_RELATIONSHIP.bad
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT_SYNONYM.ctl LOG=CONCEPT_SYNONYM.log BAD=CONCEPT_SYNONYM.bad
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=DOMAIN.ctl LOG=DOMAIN.log BAD=DOMAIN.bad
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=DRUG_STRENGTH.ctl LOG=DRUG_STRENGTH.log BAD=DRUG_STRENGTH.bad
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=RELATIONSHIP.ctl LOG=RELATIONSHIP.log BAD=RELATIONSHIP.bad
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=VOCABULARY.ctl LOG=VOCABULARY.log BAD=VOCABULARY.bad 
sqlldr OMOP_FULL_V5_ONCOLOGY/<password>@<db> CONTROL=CONCEPT_NUMERIC.ctl LOG=CONCEPT_NUMERIC.log BAD=CONCEPT_NUMERIC.bad 
