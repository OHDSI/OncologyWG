/*CREATE TABLE @cohortDatabaseSchema.episode_f (
	episode_number bigint ,
	person_id bigint,
	episode_concept_id integer ,
	episode_start_datetime date ,
	episode_end_datetime date ,
	episode_parent_id text,
	episode_type_concept_id integer ,
	episode_source_value text,
	episode_source_concept_id integer,
	identity_id text NULL
);
*/
INSERT INTO @cohortDatabaseSchema.episode_f
(
    person_id,
    episode_concept_id,
    episode_start_datetime,
    episode_end_datetime,
    episode_parent_id,
    episode_number,
    episode_object_concept_id,
    episode_type_concept_id,
    episode_source_value,
    episode_source_concept_id,
    identity_id
)
SELECT
    row_number() OVER(partition by src.person_id
    order by regimen_start_date)            AS episode_number,
    src.person_id                           AS person_id,
    32531                                   AS episode_concept_id,          -- 'Treatment Regimen'
    src.regimen_start_date                  AS episode_start_datetime,
    src.regimen_end_date                    AS episode_end_datetime,
    NULL                                    AS episode_parent_id,
    COALESCE(src.hemonc_concept_id, 0)      AS episode_object_concept_id,
    32545                                   AS episode_type_concept_id,     -- 'Episode algorithmically derived from EHR'
    NULL                                    AS episode_source_value,
    0                                       AS episode_source_concept_id,
    NULL                                    AS identity_id
FROM
    @cohortDatabaseSchema.@cancerRegimenIngredients src
GROUP BY
    src.person_id,
    src.regimen,
    src.hemonc_concept_id,
    src.regimen_start_date,
    src.regimen_end_date
;



/*
-- -------------------------------------------------------------------
-- Treatment Episode Events
-- -------------------------------------------------------------------

EXECUTE PREP_INSERT_LOG
    ( 2                             -- Step Number
    , 'PR - INS: episode_event'     -- Step Name
    , 'PROCESS - START'             -- Status
    );

COMMIT;

INSERT INTO @cohortDatabaseSchema.episode_event_f
(
    episode_id,
    event_id,
    event_table_concept_id
)
SELECT
    ep.episode_id                   AS episode_id,
    dr.drug_exposure_id             AS event_id,
    1147094                         AS event_table_concept_id   -- 'drug_exposure.drug_exposure_id'
FROM
    @cohortDatabaseSchema.@cancerRegimenIngredients src
INNER JOIN
    @cohortDatabaseSchema.episode_f ep
        ON  ep.person_id = src.person_id
        AND ep.episode_object_concept_id = COALESCE(src.hemonc_concept_id, 0)
        AND ep.episode_start_datetime = src.regimen_start_date
        AND ep.episode_end_datetime = src.regimen_end_date
        AND ep.episode_concept_id = 32531           -- 'Treatment Regimen'
INNER JOIN
    #ETL_SCHEMA_NAME#.drug_era_f de
        ON de.drug_era_id = src.drug_era_id
INNER JOIN
    #ETL_SCHEMA_NAME#.drug_strength_f ds
        ON  ds.ingredient_concept_id = de.drug_concept_id
        AND ds.invalid_reason IS NULL
INNER JOIN
    #ETL_SCHEMA_NAME#.drug_exposure_f dr
        ON dr.drug_concept_id = ds.drug_concept_id
        AND dr.person_id = src.person_id
        AND dr.drug_exposure_start_date BETWEEN src.regimen_start_date AND src.regimen_end_date
;

COMMIT;
*/
