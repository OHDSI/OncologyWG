-- *******************************************************************
-- NAME: OMOP CDM redshift load copy domain_3_6.sql
-- DESC: Load concept_synonym
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   domain
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.domain;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: domain
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.domain
    (
        domain_id
       , domain_name
       , domain_concept_id
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/DOMAIN.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1
    ;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.domain;

    COMMIT;

-- *******************************************************************
-- *******************************************************************