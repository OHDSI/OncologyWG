-- *******************************************************************
-- NAME: OMOP CDM redshift load copy drug_strength_3_7.sql
-- DESC: Load drug_strength
-- *******************************************************************
-- CHANGE LOG:
-- DATE         VERS  INITIAL  CHANGE DESCRIPTION
-- -----------  ----  -------  ------------------------------------------
-- 20-NOV-2019          1.00           Initial create
--
-- *******************************************************************

-- -------------------------------------------------------------------
-- Truncate table:   drug_strength
-- -------------------------------------------------------------------

    TRUNCATE TABLE #ETL_SCHEMA_NAME#.drug_strength;

    COMMIT;

-- -------------------------------------------------------------------
-- Load Table: drug_strength
-- -------------------------------------------------------------------

    COPY #ETL_SCHEMA_NAME#.drug_strength
    (
        drug_concept_id
       , ingredient_concept_id
       , amount_value
       , amount_unit_concept_id
       , numerator_value
       , numerator_unit_concept_id
       , denominator_value
       , denominator_unit_concept_id
       , box_size
       , valid_start_date
       , valid_end_date
       , invalid_reason
    )
    FROM '#S3_BUCKET_NAME#/vocabulary/drug_strength.csv.gz'
        CREDENTIALS 'aws_access_key_id=#S3_ACCESS_KEY#;aws_secret_access_key=#S3_SECRET_ACCESS_KEY#'
        DELIMITER '#VOCABULARY_DELIMITER#'  ACCEPTINVCHARS GZIP emptyasnull dateformat 'auto' IGNOREHEADER 1;

    COMMIT;

    ANALYSE #ETL_SCHEMA_NAME#.drug_strength;

    COMMIT;

-- *******************************************************************
-- *******************************************************************