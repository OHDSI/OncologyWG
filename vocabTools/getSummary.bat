@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

REM Specify the path to the configuration file
set "CONFIG_FILE=%~dp0config.txt"

REM Check if the configuration file exists
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
    REM Read the configuration file and set the variables
    for /f "usebackq tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        set "%%a=%%b"
    )
)

echo "Creating summary table for changes (this may take a while)..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -q -t -f  "%~dp0\sql\getSummary.sql" > "%~dp0\..\deltaVocab\deltaSummary_temp.txt"

echo "Summary table saved as deltaSummary_temp.txt."

:: Define the header lines
set "header1=      table_name      | vocabulary_id_1  | vocabulary_id_2 | standard_concept | concept_class_id |   relationship_id   | invalid_reason | concept_delta | concept_delta_percentage"
set "header2=----------------------+------------------+-----------------+------------------+------------------+---------------------+----------------+---------------+--------------------------"

:: Combine the headers with the temporary file and save the result
(echo !header1! & echo !header2! & type "%~dp0\..\deltaVocab\deltaSummary_temp.txt") > "%~dp0\..\deltaVocab\deltaSummary.txt"

:: Clean up the temporary file
del "%~dp0\..\deltaVocab\deltaSummary_temp.txt"