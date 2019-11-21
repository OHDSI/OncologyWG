-- *******************************************************************
-- NAME: OMOP CDM redshift load copy vocabulary_3_9.sql
-- DESC: Load vocabulary
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   vocabulary
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.vocabulary;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: vocabulary
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.vocabulary
    (   vocabulary_id
       , vocabulary_name
       , vocabulary_reference
       , vocabulary_version
       , vocabulary_concept_id
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/VOCABULARY.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.vocabulary;

    COMMIT;

-- *******************************************************************
-- *******************************************************************