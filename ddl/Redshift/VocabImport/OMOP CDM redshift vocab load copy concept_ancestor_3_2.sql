-- *******************************************************************
-- NAME: copy_concept_ancestor.sql
-- DESC: Load concept_ancestor
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************
-- -------------------------------------------------------------------
-- Truncate table:   concept_ancestor
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.concept_ancestor;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: concept_ancestor
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.concept_ancestor
    (
        ancestor_concept_id,
        descendant_concept_id,
        min_levels_of_separation,
        max_levels_of_separation
    )
    FROM 's3://#S3_BUCKET_NAME#/CONCEPT_ANCESTOR.csv.gz'
    CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
    DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1 ;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.concept_ancestor;

    COMMIT;

-- *******************************************************************
-- *******************************************************************
