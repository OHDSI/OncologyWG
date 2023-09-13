@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET PGPASSWORD=postgres

REM Create a temporary table
psql -U postgres -d vocab -h localhost -p 5432 -c ^
"CREATE TABLE dev.temp_concept_relationship_data (concept_id_1 integer NOT NULL, concept_id_2 integer NOT NULL, relationship_id varchar(20) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL );"

for %%F in (.\vocabTools\concept_relationship\*.csv) do (
	
	set "filename=%%~nF"
	
	REM Load the CSV data into the temporary table using \COPY
    psql -U postgres -d vocab -h localhost -p 5432 -c ^
    "\COPY dev.temp_concept_relationship_data FROM '%%F' DELIMITER ',' CSV HEADER;"
	
	echo !filename! copied to dev.concept_relationship	
)

REM Check for malformed relationship_id values in temp_concept_relationship_data
psql -U postgres -d vocab -h localhost -p 5432 -t -o invalid_relationship_ids.txt -c "SELECT relationship_id FROM dev.temp_concept_relationship_data WHERE relationship_id NOT IN ('Maps to', 'Mapped from', 'Concept replaces', 'Is a', 'Subsumes', 'Concept replaced by')"

set "INVALID_IDS="
for /f "tokens=* delims=" %%i in (invalid_relationship_ids.txt) do (
    set "INVALID_IDS=!INVALID_IDS!%%i"
)

REM Clean up the temporary file
del invalid_relationship_ids.txt

if not "!INVALID_IDS!" == "" (
	echo Error: Invalid relationship_id values found in temp_concept_relationship_data: !INVALID_IDS!

	REM Drop the temporary table
	psql -U postgres -d vocab -h localhost -p 5432 -c ^
	"DROP TABLE dev.temp_concept_relationship_data;"

	pause
	exit /b 1
) else (
	echo No invalid relationship_id values found in temp_concept_relationship_data.
)

REM TODO: Still not sure how to handle dropping concept_relationship records
REM Delete records from dev.concept_relationship based on concept IDs marked 'D' from the temporary table 
psql -U postgres -d vocab -h localhost -p 5432 -f ./vocabTools/sql/updateConceptRelationship.sql

REM Drop the temporary table
psql -U postgres -d vocab -h localhost -p 5432 -c ^
"DROP TABLE dev.temp_concept_relationship_data;"

echo All CSV files in concept_relationship folder have been copied to dev.concept_relationship. Press any key to exit
pause