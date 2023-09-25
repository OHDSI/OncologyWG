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

echo "Checking differences between dev and prod concept_relationship tables..."

psql -U !DB_USER! -d !DB_NAME! -h !DB_HOST! -p !DB_PORT! -c ^
"SELECT * FROM dev.concept_relationship EXCEPT SELECT * FROM prod.concept_relationship;"

pause