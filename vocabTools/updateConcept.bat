@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET PGPASSWORD=postgres

for %%F in (.\concept\*.csv) do (
	
	set "filename=%%~nF"
	
	REM Create a temporary table and copy the entire CSV into it
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
	"CREATE TABLE dev.temp_concept_data (concept_id integer NOT NULL, concept_name varchar(255) NOT NULL, domain_id varchar(20) NOT NULL, vocabulary_id varchar(20) NOT NULL, concept_class_id varchar(20) NOT NULL, standard_concept varchar(1) NULL, concept_code varchar(50) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL);"
	
	REM Load the CSV data into the temporary table using \COPY
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "\COPY dev.temp_concept_data FROM '%%F' DELIMITER ',' CSV HEADER;"
	
	REM Delete records from dev.concept based on concept IDs from the temporary table
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "DELETE FROM dev.concept WHERE concept_id IN (SELECT concept_id FROM dev.temp_concept_data);"
    
	REM Copy data from the temporary table to dev.concept
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "INSERT INTO dev.concept SELECT * FROM dev.temp_concept_data;"
	
	REM Drop the temporary table
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "DROP TABLE dev.temp_concept_data;"
	
	echo !filename! copied to dev.concept
	
	move "%%F" .\processed
)

echo All CSV files in concept folder have been copied to dev.concept. Press any key to exit
pause
