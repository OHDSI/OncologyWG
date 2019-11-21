-- *******************************************************************
-- NAME: OMOP CDM redshift load copy relationship_3_8.sql
-- DESC: Load relationship
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   relationship
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.relationship;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: relationship
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.relationship
    (    relationship_id
       , relationship_name
       , is_hierarchical
       , defines_ancestry
       , reverse_relationship_id
       , relationship_concept_id
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/RELATIONSHIP.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.relationship;

    COMMIT;

-- *******************************************************************
-- *******************************************************************