DELETE FROM   @cdmDatabaseSchema.episode *
WHERE episode_type_concept_id IN (
@episodeTypeConceptId
);

INSERT INTO @cdmDatabaseSchema.episode
SELECT
    row_number() OVER()   AS episode_id,
    row_number() OVER(partition by src.person_id order by regimen_start_date)
                                            AS episode_number,
    src.person_id                           AS person_id,
    32531                                   AS episode_concept_id,          -- 'Treatment Regimen'
    src.regimen_start_date                  AS episode_start_datetime,
    src.regimen_end_date                    AS episode_end_datetime,
    NULL                                    AS episode_parent_id,
    COALESCE(src.hemonc_concept_id, 0)      AS episode_object_concept_id,
    @episodeTypeConceptId                   AS episode_type_concept_id,     -- 'Episode algorithmically derived from EHR'
    NULL                                    AS episode_source_value,
    0                                       AS episode_source_concept_id,
    NULL                                    AS identity_id
FROM
    @writeDatabaseSchema.@cancerRegimenIngredients src
GROUP BY
    src.person_id,
    src.regimen,
    src.hemonc_concept_id,
    src.regimen_start_date,
    src.regimen_end_date
;



