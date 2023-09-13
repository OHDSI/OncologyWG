@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET PGPASSWORD=postgres

REM Create a temporary table
psql -U postgres -d vocab -h localhost -p 5432 -c ^
"CREATE TABLE dev.temp_concept_data (concept_id integer NOT NULL, concept_name varchar(255) NOT NULL, domain_id varchar(20) NOT NULL, vocabulary_id varchar(20) NOT NULL, concept_class_id varchar(20) NOT NULL, standard_concept varchar(1) NULL, concept_code varchar(50) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL);"
	
for %%F in (.\vocabTools\concept\*.csv) do (
	
	set "filename=%%~nF"
	
	REM Load the CSV data into the temporary table using \COPY
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "\COPY dev.temp_concept_data FROM '%%F' DELIMITER ',' CSV HEADER;"

	echo !filename! copied to dev.concept
)

REM Check for duplicate concept_id values in temp_concept_data
psql -U postgres -d vocab -h localhost -p 5432 -t -o duplicate_concept_ids.txt -c "SELECT concept_id FROM dev.temp_concept_data GROUP BY concept_id HAVING count(*) > 1;"

set "DUPLICATE_IDS="
for /f "tokens=1" %%i in (duplicate_concept_ids.txt) do (
    set "DUPLICATE_IDS=!DUPLICATE_IDS! %%i"
)

REM Clean up the temporary file
del duplicate_concept_ids.txt

if not "!DUPLICATE_IDS!" == "" (
    echo Error: Duplicate concept_id values found in temp_concept_data: !DUPLICATE_IDS!

	REM Drop the temporary table
	psql -U postgres -d vocab -h localhost -p 5432 -c ^
	"DROP TABLE dev.temp_concept_data;"

    pause
    exit /b 1
) else (
    echo No duplicate concept_id values found in temp_concept_data.
)

REM Drop constraints, update table, add constraints
psql -U postgres -d vocab -h localhost -p 5432 -f ./vocabTools/sql/updateConcept.sql

REM Drop the temporary table
psql -U postgres -d vocab -h localhost -p 5432 -c ^
"DROP TABLE dev.temp_concept_data;"
	
echo All CSV files in concept folder have been copied to dev.concept. Press any key to exit
pause