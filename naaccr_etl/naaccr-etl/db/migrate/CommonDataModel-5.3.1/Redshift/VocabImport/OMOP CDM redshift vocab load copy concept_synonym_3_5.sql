-- *******************************************************************
-- NAME: OMOP CDM redshift load copy concept_synonym_3_5.sql
-- DESC: Load concept_synonym
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   concept_synonym
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept_synonym;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: concept_synonym
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept_synonym
    (
         concept_id
       , concept_synonym_name
       , language_concept_id
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/CONCEPT_SYNONYM.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept_synonym;

    COMMIT;

-- *******************************************************************
-- *******************************************************************