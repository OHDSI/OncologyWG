@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET PGPASSWORD=postgres

for %%F in (.\concept_relationship\*.csv) do (
	
	set "filename=%%~nF"
	
	REM Create a temporary table and copy the entire CSV into it
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
	"CREATE TABLE dev.temp_concept_relationship_data (concept_id_1 integer NOT NULL, concept_id_2 integer NOT NULL, relationship_id varchar(20) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL );"
	
	REM Load the CSV data into the temporary table using \COPY
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "\COPY dev.temp_concept_relationship_data FROM '%%F' DELIMITER ',' CSV HEADER;"
	
	REM TODO: Still not sure how to handle dropping concept_relationship records
	REM Delete records from dev.concept based on concept IDs marked 'D' from the temporary table 
    psql -U postgres -d vocab -h localhost -p 5432 -f updateConceptRelationship.sql
	
	echo !filename! copied to dev.concept_relationship
	
	move "%%F" .\processed
)

echo All CSV files in concept_relationship folder have been copied to dev.concept_relationship. Press any key to exit
pause