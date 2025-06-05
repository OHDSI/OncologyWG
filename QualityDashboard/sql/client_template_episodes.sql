
with a as (
  select min(drug_exposure_start_date) as min_date from @cdm_schema.drug_exposure
  union select min(condition_start_date) from @cdm_schema.condition_occurrence
  union select min(procedure_date) from @cdm_schema.procedure_occurrence
  union select min(device_exposure_start_date) from @cdm_schema.device_exposure
  union select min(observation_date) from @cdm_schema.observation
  union select min(measurement_date) from @cdm_schema.measurement
  union select min(episode_start_date) from @cdm_schema.episode
),
b as (
  select max(drug_exposure_end_date) as max_date from @cdm_schema.drug_exposure
  union select max(condition_end_date) from @cdm_schema.condition_occurrence
  union select max(procedure_date) from @cdm_schema.procedure_occurrence
  union select max(device_exposure_end_date) from @cdm_schema.device_exposure
  union select max(observation_date) from @cdm_schema.observation
  union select max(measurement_date) from @cdm_schema.measurement
  union select max(episode_end_date) from @cdm_schema.episode
)
select 't' as domain, null as source, null as standard, count(*) as cnt
from @cdm_schema.person
union
select 'w' as domain,
min(a.min_date)-date('2000-01-01') as source, 
max(b.max_date)-date('2000-01-01') as standard,
null as cnt
from a, b
union
select 'b' as domain,
min(observation_period_start_date)-date('2000-01-01') as source, 
max(observation_period_end_date)-date('2000-01-01') as standard, 
null as cnt
from @cdm_schema.observation_period
union
select 'i' as domain, episode_source_concept_id as source, episode_concept_id as concept, count(*) as cnt
from (
  select episode_id 
  from @cdm_schema.episode
  join concepts on concept_id=episode_source_concept_id
union
  select episode_id
  from @cdm_schema.episode
  join concepts on concept_id=episode_concept_id
) a
join @cdm_schema.episode using(episode_id)
group by episode_source_concept_id, episode_concept_id
union
select 'd' as domain, drug_source_concept_id, drug_concept_id, count(*) as cnt
from (
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_source_concept_id
union
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_concept_id
) a
join @cdm_schema.drug_exposure using(drug_exposure_id)
group by drug_source_concept_id, drug_concept_id
union
select 'e' as domain, device_source_concept_id, device_concept_id, count(*) as cnt
from (
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_source_concept_id
union
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_concept_id
) a
join @cdm_schema.device_exposure using(device_exposure_id)
group by device_source_concept_id, device_concept_id
union
select 'p' as domain, procedure_source_concept_id, procedure_concept_id, count(*) as cnt
from (
  select procedure_occurrence_id
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_source_concept_id
union
  select procedure_occurrence_id 
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_concept_id
) a
join @cdm_schema.procedure_occurrence using(procedure_occurrence_id)
group by procedure_source_concept_id, procedure_concept_id
union
select 'c' as domain, condition_source_concept_id, condition_concept_id, count(*) as cnt
from (
  select condition_occurrence_id 
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_source_concept_id
union
  select condition_occurrence_id
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_concept_id
) a
join @cdm_schema.condition_occurrence using(condition_occurrence_id)
group by condition_source_concept_id, condition_concept_id
union
select 'o' as domain, observation_source_concept_id, observation_concept_id, count(*) as cnt
from (
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_source_concept_id
union
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_concept_id
) a
join @cdm_schema.observation using(observation_id)
group by observation_source_concept_id, observation_concept_id
union
select 'm' as domain, measurement_source_concept_id, measurement_concept_id, count(*) as cnt
from (
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_source_concept_id
union
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_concept_id
) a
join @cdm_schema.measurement using(measurement_id)
group by measurement_source_concept_id, measurement_concept_id
union
select 'v' as domain, null, value_as_concept_id, count(*) as cnt
from @cdm_schema.measurement
join concepts on concept_id=value_as_concept_id
group by value_as_concept_id
;
