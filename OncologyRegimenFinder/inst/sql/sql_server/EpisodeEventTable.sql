-- -------------------------------------------------------------------
-- Treatment Episode Events
-- -------------------------------------------------------------------
DELETE FROM @cdmDatabaseSchema.episode_event *
WHERE event_table_concept_id
IN (@episodeEventTableConceptId);

INSERT INTO @cdmDatabaseSchema.episode_event
SELECT
    ep.episode_id                   AS episode_id,
    dr.drug_exposure_id             AS event_id,
    --1147094
    @episodeEventTableConceptId AS event_table_concept_id   -- 'drug_exposure.drug_exposure_id'
FROM
    @writeDatabaseSchema.@cancerRegimenIngredients src
INNER JOIN
    @cdmDatabaseSchema.episode ep
        ON  ep.person_id = src.person_id
        AND ep.episode_object_concept_id = COALESCE(src.hemonc_concept_id, 0)
        AND ep.episode_start_datetime = src.regimen_start_date
        AND ep.episode_end_datetime = src.regimen_end_date
        AND ep.episode_concept_id = 32531           -- 'Treatment Regimen'
INNER JOIN
    @cdmDatabaseSchema.drug_era de
        ON de.drug_era_id = src.drug_era_id
INNER JOIN
    @cdmDatabaseSchema.drug_strength ds
        ON  ds.ingredient_concept_id = de.drug_concept_id
        AND ds.invalid_reason IS NULL
INNER JOIN
    @cdmDatabaseSchema.drug_exposure dr
        ON dr.drug_concept_id = ds.drug_concept_id
        AND dr.person_id = src.person_id
        AND dr.drug_exposure_start_date BETWEEN src.regimen_start_date AND src.regimen_end_date
;
