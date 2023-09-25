@echo off
setlocal

:: Set the URL of the CSV file on GitHub
set "concept_url=https://raw.githubusercontent.com/OHDSI/OncologyWG/vocabTools/deltaVocab/deltaConcept.csv"
set "concept_relationship_url=https://raw.githubusercontent.com/OHDSI/OncologyWG/vocabTools/deltaVocab/deltaConceptRelationship.csv"

:: Set the output file name
set "concept_file=%~dp0/output/deltaConcept.csv"
set "concept_relationship_file=%~dp0/output/deltaConceptRelationship.csv"

:: Use curl to download the CSV file
curl -o "%concept_file%" "%concept_url%"
curl -o "%concept_relationship_file%" "%concept_relationship_url%"

:: Check if the download was successful
if %errorlevel% equ 0 (
    echo CSV file downloaded successfully.
) else (
    echo Error downloading CSV file.
)

echo Updating delta tables...
:: Run the Python script for data merging
python %~dp0python/updateDelta.py

:: Other batch script commands here (e.g., moving files, creating backups, etc.)
:: ...

endlocal
