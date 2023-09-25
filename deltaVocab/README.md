# OHDSI Oncology Workgroup deltaVocab

## Purpose

This folder contains two files:
- deltaConcept
- deltaConceptRelationship

These files, in conjunction with the scripts in the vocabTools folder, can be used to **augment** the latest official release of the OMOP Vocabulary. They are not meant as a replacement for the OMOP Vocabulary but rather as proposed changes that will eventually be integrated into the main release. These files can be used to transform the official OMOP Vocabulary into the Oncology Development Vocabulary

Maintaining the **change** between the official OMOP Vocabulary release and the Oncology Development Vocabulary allows for rapid development of OHDSI Oncology studies that are untethered from the official OMOP Vocabulary release cadence. By preserving only the changed elements, instead of the entire Oncology Development Vocabulary, this method provides a lightweight, GitHub-friendly solution, that is also respectful of (by way of avoiding) the licensed vocabulary terms.

## Instructions

### Download
To create the Oncology Development Vocabulary, you must download the **vocabTools** and **deltaVocab** folders from the OHDSI/OncologyWG repository. It may be simplest to clone the OHDSI/OncologyWG and work from there:

`git clone https://github.com/OHDSI/OncologyWG.git`

### Configure

These methods assume you have the latest official release of the OMOP Vocabulary in *two identical schemas* in a Postgres database:
- **prod**: The **prod** schema contains the official ("production") OMOP Vocabulary. This vocabulary will not be changed but can be used to refresh the **dev** schema.
- **dev**: The **dev** schema begins as an exact copy of the official OMOP Vocabulary, but will be transformed into the Oncology Development Vocabulary using the deltaVocab files and the scripts in vocabTools.

To enable the scripts in vocabTools, enter your database connection details into the **config.txt** file.

### Augment

Create two folders in the vocabTools folder: concept and concept_relationship.

Move the deltaConcept.csv and deltaConceptRelationship.csv files to the new concept and concept_relationship folders, respectively.

Run **updateConcept.bat** to implement the changes from deltaConcept to the dev schema in your database.

Run **updateConceptRelationship.bat** to implement the changes from deltaConceptRelationship to the dev schema in your database.

Run **updateConceptAncestor.bat** to rebuild concept_ancestor based on the new concept and concept_relationship tables in the dev schema.
