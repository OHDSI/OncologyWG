-- *******************************************************************
-- NAME: copy_concept_class.sql
-- DESC: Load Concept Table
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   concept_class
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept_class;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: concept_class
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept_class
    (
        concept_class_id,
        concept_class_name,
        concept_class_concept_id
    )
    FROM 's3://#S3_BUCKET_NAME#/CONCEPT_CLASS.csv.gz'
    CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
    DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1 ;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept_class;

    COMMIT;

-- *******************************************************************
-- *******************************************************************