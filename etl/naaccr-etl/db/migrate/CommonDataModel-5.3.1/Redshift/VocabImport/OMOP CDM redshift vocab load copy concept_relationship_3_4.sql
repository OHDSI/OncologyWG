-- *******************************************************************
-- NAME: copy_concept_relationship.sql
-- DESC: Load concept_relationship
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   concept_relationship
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept_relationship;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: concept_relationship
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept_relationship
    (
        concept_id_1,
        concept_id_2,
        relationship_id,
        valid_start_date,
        valid_end_date,
        invalid_reason
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/CONCEPT_RELATIONSHIP.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1
    ;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept_relationship;

    COMMIT;

-- *******************************************************************
-- *******************************************************************