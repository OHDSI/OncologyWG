
-- Adding the lab test concepts to the overall list of concepts to count
insert into concepts
select measurement_concept_id as concept_id
from test
left join concepts on measurement_concept_id = concept_id
where concept_id is null;

/************************************************************************************
Creating complete list of source and standard concept pairs and their absolute counts
In addition, distribution of values for select lab tests
No patient-level information is captured
************************************************************************************/
-- the first date in the clinical event tables
with a as (
  select min(drug_exposure_start_date) as min_date from @cdm_schema.drug_exposure
  union select min(condition_start_date) from @cdm_schema.condition_occurrence
  union select min(procedure_date) from @cdm_schema.procedure_occurrence
  union select min(device_exposure_start_date) from @cdm_schema.device_exposure
  union select min(observation_date) from @cdm_schema.observation
  union select min(measurement_date) from @cdm_schema.measurement
),
-- the last date in the clinical event tables
b as (
  select max(drug_exposure_end_date) as max_date from @cdm_schema.drug_exposure
  union select max(condition_end_date) from @cdm_schema.condition_occurrence
  union select max(procedure_date) from @cdm_schema.procedure_occurrence
  union select max(device_exposure_end_date) from @cdm_schema.device_exposure
  union select max(observation_date) from @cdm_schema.observation
  union select max(measurement_date) from @cdm_schema.measurement
),
-- Distribution of lab test results as 3rd, 25th, median, 75th and 97th percentile
-- Max and min values are often outliers, 3rd and 97th is used instead
lab_values as (
  select {@dialect == 'sql server'} ? {distinct} measurement_concept_id, unit_concept_id, range_low,
  range_high, value_as_concept_id,
  percentile_cont(0.03) within group (order by value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as p_03, 
  percentile_cont(0.25) within group (order by value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as p_25, 
  percentile_cont(0.5) within group (order by value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as median,
  percentile_cont(0.75) within group (order by value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as p_75,
  percentile_cont(0.97) within group (order by value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as p_97,
  count(value_as_number) {@dialect == 'sql server'} ? {over (partition by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id)} as cnt
  from (
    select m.measurement_concept_id, unit_concept_id, range_low,
    range_high, value_as_concept_id, value_as_number
    from @cdm_schema.measurement m
    join test t on t.measurement_concept_id = m.measurement_concept_id
    where value_as_number!=0 and value_as_number is not null
    union all
    select observation_concept_id, unit_concept_id, null as range_low, 
    null as range_high, value_as_concept_id, value_as_number
    from @cdm_schema.observation
    join test on observation_concept_id=measurement_concept_id
    where value_as_number!=0 and value_as_number is not null
  ) as c
  {@dialect != 'sql server'} ? {group by measurement_concept_id, unit_concept_id, range_low, range_high, value_as_concept_id}
)
-- Total patient count in the database
select 't' as domain, null as source, null as standard, count(*) as cnt, null as measurement
from @cdm_schema.person
union
-- The very first start date and the very last end dates across all domains
select 'w' as domain,
DATEDIFF(DAY, '2000-01-01', MIN(a.min_date)) as source, 
DATEDIFF(DAY, '2000-01-01', MAX(b.max_date)) as standard,
null as cnt, null as measurement
from a, b
union
-- First and last day of any observation period
select 'b' as domain,
DATEDIFF(DAY, '2000-01-01', MIN(observation_period_start_date)) as source, 
DATEDIFF(DAY, '2000-01-01', MAX(observation_period_end_date)) as standard, 
null as cnt, null as measurement
from @cdm_schema.observation_period
union
-- Source and standard drug concept counts
select 'd' as domain, drug_source_concept_id, drug_concept_id, count(*) as cnt, null as measurement
from (
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_source_concept_id
union
  select drug_exposure_id 
  from @cdm_schema.drug_exposure
  join concepts on concept_id=drug_concept_id
) as a
join @cdm_schema.drug_exposure d on a.drug_exposure_id = d.drug_exposure_id
group by drug_source_concept_id, drug_concept_id
union
-- Source and standard device concept counts
select 'e' as domain, device_source_concept_id, device_concept_id, count(*) as cnt, null as measurement
from (
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_source_concept_id
union
  select device_exposure_id 
  from @cdm_schema.device_exposure
  join concepts on concept_id=device_concept_id
) as a
join @cdm_schema.device_exposure d on d.device_exposure_id = a.device_exposure_id
group by device_source_concept_id, device_concept_id
union
-- Source and standard procedure concept counts
select 'p' as domain, procedure_source_concept_id, procedure_concept_id, count(*) as cnt, null as measurement
from (
  select procedure_occurrence_id
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_source_concept_id
union
  select procedure_occurrence_id 
  from @cdm_schema.procedure_occurrence
  join concepts on concept_id=procedure_concept_id
) as a
join @cdm_schema.procedure_occurrence p on p.procedure_occurrence_id = a.procedure_occurrence_id
group by procedure_source_concept_id, procedure_concept_id
union
-- Source and standard condition concept counts
select 'c' as domain, condition_source_concept_id, condition_concept_id, count(*) as cnt, null as measurement
from (
  select condition_occurrence_id 
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_source_concept_id
union
  select condition_occurrence_id
  from @cdm_schema.condition_occurrence
  join concepts on concept_id=condition_concept_id
) as a
join @cdm_schema.condition_occurrence o on o.condition_occurrence_id = a.condition_occurrence_id
group by condition_source_concept_id, condition_concept_id
union
-- Source and standard observation concept counts
select 'o' as domain, observation_source_concept_id, observation_concept_id, count(*) as cnt, null as measurement
from (
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_source_concept_id
union
  select observation_id 
  from @cdm_schema.observation
  join concepts on concept_id=observation_concept_id
) as a
join @cdm_schema.observation o on o.observation_id = a.observation_id
group by observation_source_concept_id, observation_concept_id
union
-- Source and standard measurement concept counts
select 'm' as domain, measurement_source_concept_id, measurement_concept_id, count(*) as cnt, null as measurement
from (
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_source_concept_id
union
  select measurement_id 
  from @cdm_schema.measurement
  join concepts on concept_id=measurement_concept_id
) as a
join @cdm_schema.measurement m on m.measurement_id = a.measurement_id
group by measurement_source_concept_id, measurement_concept_id
union
-- Measurement value concept counts
select 'v' as domain, null, value_as_concept_id, count(*) as cnt, null as measurement
from @cdm_schema.measurement
join concepts on concept_id=value_as_concept_id
group by value_as_concept_id
union
-- Lab value distribution as string for transport purposes
select 'l' as domain, measurement_concept_id, unit_concept_id, value_as_concept_id,
coalesce(cast(range_low as varchar), '') + '~' + 
coalesce(cast(range_high as varchar), '') + '~' +
coalesce(cast(p_03 as varchar), '') + '~' +
coalesce(cast(p_25 as varchar), '') + '~' +
coalesce(cast(median as varchar), '') + '~' +
coalesce(cast(p_75 as varchar), '') + '~' +
coalesce(cast(p_97 as varchar), '') + '~' +
coalesce(cast(cnt as varchar), '')
as measurement
from lab_values
;
