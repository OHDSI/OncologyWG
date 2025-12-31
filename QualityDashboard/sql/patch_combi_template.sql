
create table @patch_schema.condition_new as -- could also be written directly into CONDITION_OCCURRENCE, if you feel lucky
with topo as ( -- find all records with topology concepts or pseudo-topology concepts disguised as disease concepts with generic histology (malignant neoplasm etc.) 
  select -- the topo record carries all the extra attributes
    person_id, condition_start_date as start_date, condition_start_datetime, condition_end_date, condition_end_datetime, condition_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, condition_status_concept_id,
    combo.*
  from @cdm_schema.condition_occurrence join @patch_schema.combo on topo_id=condition_concept_id
union
  select -- from the observation
    person_id, observation_date as start_date, observation_datetime, cast(null as date), cast(null as timestamp), observation_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, cast(null as integer),
    combo.*
  from @cdm_schema.observation join @patch_schema.combo on topo_id=observation_concept_id
),
histo as (  -- find all records with histology concepts or pseudo-histology concepts disguised as disease concepts with no finding site
  select person_id, condition_start_date as start_date, combo.*
  from @cdm_schema.condition_occurrence join @patch_schema.combo on histo_id=condition_concept_id
union
  select person_id, observation_date as start_date, combo.*
  from @cdm_schema.observation join @patch_schema.combo on histo_id=observation_concept_id
)
select -- combine them as long as they occur in the same patient on the same day, and write them out as new conditions
  (select max(condition_occurrence_id) from @cdm_schema.condition_occurrence)+row_number() over (order by person_id) as condition_occurrence_id, combined.* 
  from (
    select distinct person_id, cancer_id as condition_concept_id, start_date as condition_start_date, condition_start_datetime, condition_end_date, condition_end_datetime, condition_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, condition_status_concept_id
    from topo
    join histo using(person_id, start_date, cancer_id) -- histo and topo have to be in combo and occur on the same date for the same patient
) combined
;
