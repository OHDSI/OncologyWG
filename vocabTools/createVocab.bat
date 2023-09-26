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
    echo BASE_PATH
    pause
    exit
) else (
    REM Read the configuration file and set the variables
    for /f "usebackq tokens=1,* delims==" %%a in (!CONFIG_FILE!) do (
        set "%%a=%%b"
    )
)

echo "Executing DDL script..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f "%~dp0\sql\prodVocabDDL.sql"

echo "Populating prod vocabulary tables..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c "SET search_path to prod; SELECT public.populate_vocabulary('!BASE_PATH!');"

echo "Indexing prod vocabulary tables..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f "%~dp0\sql\prodVocabIndex.sql"

echo "Populating dev vocabulary tables..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -f "%~dp0\sql\refreshDev.sql"

pause
