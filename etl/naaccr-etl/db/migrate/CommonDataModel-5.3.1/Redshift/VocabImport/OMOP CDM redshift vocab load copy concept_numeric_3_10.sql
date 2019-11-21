-- *******************************************************************
-- NAME: OMOP CDM redshift load copy concept_numeric_3_10.sql
-- DESC: Load concept_numeric
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   concept_numeric
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept_numeric;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: concept_numeric
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept_numeric
    (    concept_id
       , value_as_number
       , unit_concept_id
       , operator_concept_id
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/CONCEPT_NUMERIC.csv'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER ','  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept_numeric;

    COMMIT;

-- *******************************************************************
-- *******************************************************************