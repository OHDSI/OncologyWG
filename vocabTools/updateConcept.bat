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
"CREATE TABLE dev.temp_concept_data (concept_id integer NOT NULL, concept_name varchar(255) NOT NULL, domain_id varchar(20) NOT NULL, vocabulary_id varchar(20) NOT NULL, concept_class_id varchar(20) NOT NULL, standard_concept varchar(1) NULL, concept_code varchar(50) NOT NULL, valid_start_date date NOT NULL, valid_end_date date NOT NULL, invalid_reason varchar(1) NULL);"

for %%F in ("%~dp0\concept\*.csv") do (
	
	set "filename=%%~nF"
	
	:: Load the CSV data into the temporary table using \COPY
    psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
    "\COPY dev.temp_concept_data FROM '%%F' DELIMITER ',' CSV HEADER;"

	echo !filename! copied to dev.concept
)

:: Check for duplicate concept_id values in temp_concept_data
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -t -o duplicate_concept_ids.txt -c "SELECT concept_id FROM dev.temp_concept_data GROUP BY concept_id HAVING count(*) > 1;"

set "DUPLICATE_IDS="
for /f "tokens=1" %%i in (duplicate_concept_ids.txt) do (
    set "DUPLICATE_IDS=!DUPLICATE_IDS! %%i"
)

:: Clean up the temporary file
del duplicate_concept_ids.txt

if not "!DUPLICATE_IDS!" == "" (
    echo Error: Duplicate concept_id values found in temp_concept_data: !DUPLICATE_IDS!

	:: Drop the temporary table
	psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
	"DROP TABLE dev.temp_concept_data;"

    pause
    exit /b 1
) else (
    echo No duplicate concept_id values found in temp_concept_data.
)

:: Drop constraints, update table, add constraints
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f "%~dp0\sql\updateConcept.sql"

:: Drop the temporary table
psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
"DROP TABLE dev.temp_concept_data;"
	
echo All CSV files in concept folder have been copied to dev.concept. Press any key to exit
pause