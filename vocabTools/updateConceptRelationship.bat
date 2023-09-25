@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Specify the path to the configuration file
set "CONFIG_FILE=%~dp0config.txt"

:: Check if the configuration file exists
if not exist !CONFIG_FILE! (
    echo Configuration file "!CONFIG_FILE!" not found. Please create a file in the same directory as the bat file called config.txt with variables:
	echo PGPASSWORD
	echo DB_USER
	echo DB_NAME
	echo DB_HOST
	echo DB_PORT
	pause
	exit
) else (
    :: Read the configuration file and set the variables
    for /f "usebackq tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        set "%%a=%%b"
    )
)

:: Create a temporary table
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
"CREATE TABLE dev.temp_concept_relationship_data (concept_id_1 integer NOT NULL, concept_id_2 integer NOT NULL, relationship_id varchar(20) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL );"

for %%F in ("%~dp0\concept_relationship\*.csv") do (
	
	set "filename=%%~nF"
	
	:: Load the CSV data into the temporary table using \COPY
    psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
    "\COPY dev.temp_concept_relationship_data FROM '%%F' DELIMITER ',' CSV HEADER;"
	
	echo !filename! copied to dev.concept_relationship	
)

:: Check for malformed relationship_id values in temp_concept_relationship_data
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -t -o invalid_relationship_ids.txt -c "SELECT relationship_id FROM dev.temp_concept_relationship_data WHERE relationship_id NOT IN ('Maps to', 'Mapped from', 'Concept replaces', 'Is a', 'Subsumes', 'Concept replaced by')"

set "INVALID_IDS="
for /f "tokens=* delims=" %%i in (invalid_relationship_ids.txt) do (
    set "INVALID_IDS=!INVALID_IDS!%%i"
)

:: Clean up the temporary file
del invalid_relationship_ids.txt

if not "!INVALID_IDS!" == "" (
	echo Error: Invalid relationship_id values found in temp_concept_relationship_data: !INVALID_IDS!

	:: Drop the temporary table
	psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
	"DROP TABLE dev.temp_concept_relationship_data;"

	pause
	exit /b 1
) else (
	echo No invalid relationship_id values found in temp_concept_relationship_data.
)

:: TODO: Still not sure how to handle dropping concept_relationship records
:: Delete records from dev.concept_relationship based on concept IDs marked 'D' from the temporary table 
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f "%~dp0\sql\updateConceptRelationship.sql"

:: Drop the temporary table
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
"DROP TABLE dev.temp_concept_relationship_data;"

echo All CSV files in concept_relationship folder have been copied to dev.concept_relationship. Press any key to exit
pause