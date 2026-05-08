-- *******************************************************************
-- NAME: OMOP CDM redshift load copy concept_3_1.sql
-- DESC: Load Concept Table
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   concept
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table:   concept
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept
    (
        concept_id,
        concept_name,
        domain_id,
        vocabulary_id,
        concept_class_id,
        standard_concept,
        concept_code,
        valid_start_date,
        valid_end_date,
        invalid_reason
    )
    FROM 's3://#S3_BUCKET_NAME#/CONCEPT.csv.gz'
    CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
    DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1 ;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept;

    COMMIT;

-- *******************************************************************
-- *******************************************************************
