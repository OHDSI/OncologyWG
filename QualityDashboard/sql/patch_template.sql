-- create staging table wich only contains copies of records that need fixing
-- equivalent fields are combined, unique fields stay separate
drop table if exists staging;
create table staging as
with concept as (
  select concept_id from patch.mapping -- value_to should be covered
union
  select concept_id from patch.new_concept
)
select t.*, target_concept_id, coalesce(m.target_domain_id, n.target_domain_id) as target_domain_id, target_value_as_concept_id from (
  select 
    'Drug' as source_domain_id, -- instead of table name
    drug_exposure_id as event_id, --1
    person_id as person_id, --2
    drug_concept_id as concept_id, --3
    drug_exposure_start_date as start_date, --4
    drug_exposure_start_datetime as Start_datetime, --5
    drug_type_concept_id as type_concept_id, --6
    provider_id as provider_id, --7
    visit_occurrence_id as visit_occurrence_id, --8
    visit_detail_id as visit_detail_id, --9
    drug_source_value as source_value, --10
    drug_source_concept_id as source_concept_id, --11
    drug_exposure_end_date as end_date, --12
    drug_exposure_end_datetime as end_datetime, --13
    quantity as quantity, --14
    cast (null as numeric) as value_as_number, --15
    cast (null as integer) as value_as_concept_id, --16
    cast (null as integer) as unit_concept_id, --17
    cast (null as varchar(50)) as unit_source_value, --18
    verbatim_end_date as verbatim_end_date, --19
    stop_reason as stop_reason, --20
    refills as refills, --21
    days_supply as days_supply, --22
    sig as sig, --23
    route_concept_id as route_concept_id, --24
    lot_number as lot_number, --25
    route_source_value as route_source_value, --26
    dose_unit_source_value as dose_unit_source_value, --27
    cast (null as varchar(255)) as unique_device_id, --28
    cast (null as varchar(255)) as production_id, --29
    cast (null as integer) as modifier_concept_id, --30
    cast (null as varchar(50)) as modifier_source_value, --31
    cast (null as varchar(50)) as condition_status_source_value, --32
    cast (null as integer) as condition_status_concept_id, --33
    cast (null as varchar(60)) as value_as_string, --35
    cast (null as integer) as qualifier_concept_id, --36
    cast (null as varchar(50)) as qualifier_source_value, --37
    cast (null as integer) as unit_source_concept_id, --38
    cast (null as varchar(10)) as measurement_time, --39
    cast (null as integer) as operator_concept_id, --40
    cast (null as numeric) as range_low, --41
    cast (null as numeric) range_high --42
  from cdm.drug_exposure join concept on concept_id=drug_concept_id
union
  select all
    'Device' as source_domain_id, -- instead of table name
    device_exposure_id, --1
    person_id, --2
    device_concept_id, --3
    device_exposure_start_date, --4
    device_exposure_start_datetime, --5
    device_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    device_source_value, --10
    device_source_concept_id, --11
    device_exposure_end_date, --12
    device_exposure_end_datetime, --13
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, --14-27
    unique_device_id, --28
    production_id, --29
    null, null, null, null, null, null, null, null, null, null, null, null --30-42 (except 34)
  from cdm.device_exposure join concept on concept_id=device_concept_id
union
  select
    'Procedure' as source_domain_id, -- instead of table name
    procedure_occurrence_id, --1
    person_id, --2
    procedure_concept_id, --3
    procedure_date, --4
    procedure_datetime, --5
    procedure_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    procedure_source_value, --10
    procedure_source_concept_id, --11
    null, null, --12-13
    quantity, --14
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, --15-29
    modifier_concept_id, --30
    modifier_source_value, --31
    null, null, null, null, null, null, null, null, null, null --32-42 (except 34)
  from cdm.procedure_occurrence join concept on concept_id=procedure_concept_id
union
  select
    'Condition' as source_domain_id, -- instead of table name
    condition_occurrence_id, --1
    person_id, --2
    condition_concept_id, --3
    condition_start_date, --4
    condition_start_datetime, --5
    condition_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    condition_source_value, --10
    condition_source_concept_id, --11
    condition_end_date, --12
    condition_end_datetime, --13
    null, null, null, null, null, null, --14-19
    stop_reason, --20 (was 34)
    null, null, null, null, null, null, null, null, null, null, null, --21-31
    condition_status_source_value, --32
    condition_status_concept_id, --33
    null, null, null, null, null, null, null, null --35-42
  from cdm.condition_occurrence join concept on concept_id=condition_concept_id
union
  select
    'Observation' as source_domain_id, -- instead of table name
    observation_id, --1
    person_id, --2
    observation_concept_id, --3
    observation_date, --4
    observation_datetime, --5
    observation_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    observation_source_value, --10
    observation_source_concept_id, --11
    null, null, null, --12-14
    value_as_number, --15
    case value_as_concept_id when 0 then null else value_as_concept_id end, --16
    unit_concept_id, --17
    unit_source_value, --18
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, --19-33 (double 34 step_reason gone)
    value_as_string, --35
    qualifier_concept_id, --36
    qualifier_source_value, --37
    null, null, null, null, null --38-42
  from cdm.observation join concept on concept_id=observation_concept_id
union
  select
    'Measurement' as source_domain_id, -- instead of table name
    measurement_id, --1
    person_id, --2
    measurement_concept_id, --3
    measurement_date, --4
    measurement_datetime, --5
    measurement_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    measurement_source_value, --10
    measurement_source_concept_id, --11
    null, null, null, --12-14
    value_as_number, --15
    case value_as_concept_id when 0 then null else value_as_concept_id end, --16
    unit_concept_id, --17
    unit_source_value, --18
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, --19-37 (except 34)
    unit_source_concept_id, --38
    measurement_time, --39
    operator_concept_id, --40
    range_low, --41
    range_high --42
  from cdm.measurement join concept on concept_id=measurement_concept_id
union
  select
    'Meas Value' as source_domain_id, -- instead of table name
    null, --1
    person_id, --2
    value_as_concept_id, --3
    measurement_date, --4
    measurement_datetime, --5
    measurement_type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, --10-38 (except 34)
    measurement_time, --39
    operator_concept_id, --40
    range_low, --41
    range_high --42
  from cdm.measurement join concept on concept_id=value_as_concept_id
) t left join patch.mapping m using(concept_id) left join patch.new_concept n using(concept_id) left join patch.to_value using(concept_id)
-- only use if the concept needs to be replaced, or the record needs a domain change, or if there needs to be a post-coordination in Measurements or Observations
where target_concept_id is not null or source_domain_id!=coalesce(m.target_domain_id, n.target_domain_id) or target_value_as_concept_id is not null
;


/************************
-- Writing out new tables
************************/
-- Copy of DRUG_EXPOSURE except those that are in staging
drop table if exists drug_exposure_new;
create table drug_exposure_new as
select * from cdm.drug_exposure where drug_exposure_id not in (select event_id from staging where source_domain_id='Drug')
;
-- Add from staging
insert into drug_exposure_new(drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, drug_exposure_start_datetime, drug_source_value, drug_source_concept_id, drug_exposure_end_date, drug_exposure_end_datetime, quantity, verbatim_end_date, stop_reason, refills, days_supply, sig, route_concept_id, lot_number, route_source_value, dose_unit_source_value)
with i as (
  select distinct
    person_id as person_id, --2
    coalesce(target_concept_id, concept_id) as drug_concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as drug_exposure_start_date, --4
    cast(start_datetime as timestamp) as drug_exposure_start_datetime, --5
    type_concept_id as drug_type_concept_id, --6
    provider_id as provider_id, --7
    visit_occurrence_id as visit_occurrence_id, --8
    visit_detail_id as visit_detail_id, --9
    source_value as drug_source_value, --10
    source_concept_id as drug_source_concept_id, --11
    cast(end_date as date) as drug_exposure_end_date, --12
    cast(end_datetime as timestamp) as drug_exposure_end_datetime, --13
    quantity as quantity, --14
    cast(verbatim_end_date as date) as verbatim_end_date, --19
    stop_reason as stop_reason, --20
    refills as refills, --21
    days_supply as days_supply, --22
    sig as Sig, --23
    route_concept_id as route_concept_id, --24
    lot_number as lot_number, --25
    route_source_value as route_source_value, --26
    dose_unit_source_value as dose_unit_source_value --27
  from staging where coalesce(target_domain_id, source_domain_id)='Drug' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(drug_exposure_id) from cdm.drug_exposure) + row_number() over () as drug_exposure_id,
  person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
-- the following is to deduplicate records if the orginal CDM copied them across tables.
-- for the fields that are not univeral we want to suppress the nulls, but otherwise use the first value, whatever it might be.
-- start_datetime should not be part of the deduplication because cancer data are not sensitive to timing less than one day.
  first_value(drug_exposure_start_datetime) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by drug_exposure_start_date nulls last) as drug_exposure_start_datetime,
  first_value(drug_source_value) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by drug_source_concept_id nulls last) as drug_source_value,
  first_value(drug_source_concept_id) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by drug_source_concept_id nulls last) as drug_source_concept_id,
-- we should prefer the latest end_date
  first_value(drug_exposure_end_date) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by drug_exposure_end_date desc nulls last) as drug_exposure_end_date,
  first_value(drug_exposure_end_datetime) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by drug_exposure_end_date desc nulls last) as drug_exposure_end_datetime,
  first_value(quantity) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by quantity nulls last) as quantity,
  first_value(verbatim_end_date) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by verbatim_end_date desc nulls last) as verbatim_end_date,
  first_value(stop_reason) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by stop_reason nulls last) as stop_reason,
  first_value(refills) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by refills nulls last) as refills,
  first_value(days_supply) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by days_supply nulls last) as days_supply,
  first_value(sig) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by sig nulls last) as sig,
  first_value(route_concept_id) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by route_concept_id nulls last) as route_concept_id,
  first_value(lot_number) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by lot_number nulls last) as lot_number,
  first_value(route_source_value) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by route_concept_id nulls last) as route_source_value,
  first_value(dose_unit_source_value) over (partition by person_id, drug_concept_id, drug_exposure_start_date, drug_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by dose_unit_source_value nulls last) as dose_unit_source_value
from i
;

-- Copy of DEVICE_EXPOSURE except those that are in staging
drop table if exists device_exposure_new;
create table device_exposure_new as
select * from cdm.device_exposure where device_exposure_id not in (select event_id from staging where source_domain_id='Device')
;
-- Add from staging
insert into device_exposure_new(device_exposure_id, person_id, device_concept_id, device_exposure_start_date, device_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, device_exposure_start_datetime, device_source_value, device_source_concept_id, device_exposure_end_date, device_exposure_end_datetime, unique_device_id, production_id)
with i as (
  select distinct
    person_id, --2
    coalesce(target_concept_id, concept_id) as concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as start_date, --4
    cast(start_datetime as timestamp) as start_datetime, --5
    type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    source_value, --10
    source_concept_id, --11
    cast(end_date as date) as end_date, --12
    cast(end_datetime as timestamp) as end_datetime, --13
    unique_device_id, --28
    production_id --29
  from staging where coalesce(target_domain_id, source_domain_id)='Device' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(device_exposure_id) from cdm.device_exposure) + row_number() over () as event_id,
  person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
  first_value(start_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by start_date nulls last) as start_datetime,
  first_value(source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_value,
  first_value(source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_concept_id,
  first_value(end_date) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by end_date desc nulls last) as end_date,
  first_value(end_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by end_date desc nulls last) as end_datetime,
  first_value(unique_device_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unique_device_id nulls last) as unique_device_id,
  first_value(production_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by production_id nulls last) as production_id
from i
;

-- Copy of PROCEDURE_OCCURRENCE except those that are in staging
drop table if exists procedure_occurrence_new;
create table procedure_occurrence_new as
select * from cdm.procedure_occurrence where procedure_occurrence_id not in (select event_id from staging where source_domain_id='Procedure')
;
insert into procedure_occurrence_new(procedure_occurrence_id, person_id, procedure_concept_id, procedure_date, procedure_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, procedure_datetime, procedure_source_value, procedure_source_concept_id, quantity, modifier_concept_id, modifier_source_value)
with i as (
  select distinct
    person_id, --2
    coalesce(target_concept_id, concept_id) as concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as start_date, --4
    cast(start_datetime as timestamp) as start_datetime, --5
    type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    source_value, --10
    source_concept_id, --11
    quantity, --14
    modifier_concept_id, --30
    modifier_source_value --31
  from staging where coalesce(target_domain_id, source_domain_id)='Procedure' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(procedure_occurrence_id) from cdm.procedure_occurrence) + row_number() over () as event_id,
  person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
  first_value(start_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by start_datetime nulls last) as start_datetime,
  first_value(source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_value,
  first_value(source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_concept_id,
  first_value(quantity) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by quantity nulls last) as quantity,
  first_value(modifier_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by modifier_concept_id nulls last) as modifier_concept_id,
  first_value(modifier_source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by modifier_concept_id nulls last) as modifier_source_value
from i
;

-- Copy of CONDITION_OCCURRENCE except those that are in staging
drop table if exists condition_occurrence_new;
create table condition_occurrence_new as
select * from cdm.condition_occurrence where condition_occurrence_id not in (select event_id from staging where source_domain_id='Condition')
;
insert into condition_occurrence_new(condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, condition_start_datetime, condition_source_value, condition_source_concept_id, condition_end_date, condition_end_datetime, stop_reason, condition_status_source_value, condition_status_concept_id)
with i as (
  select distinct
    person_id, --2
    coalesce(target_concept_id, concept_id) as concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as start_date, --4
    cast(start_datetime as timestamp) as start_datetime, --5
    type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    source_value, --10
    source_concept_id, --11
    cast(end_date as date) as end_date, --12
    cast(end_datetime as timestamp) as end_datetime, --13
    stop_reason, --20
    condition_status_source_value, --32
    condition_status_concept_id --33
  from staging where coalesce(target_domain_id, source_domain_id)='Condition' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(condition_occurrence_id) from cdm.condition_occurrence) + row_number() over () as event_id,
  person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
  first_value(start_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by start_datetime nulls last) as start_datetime,
  first_value(source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_value,
  first_value(source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_concept_id,
  first_value(end_date) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by end_date desc nulls last) as end_date,
  first_value(end_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by end_date desc nulls last) as end_datetime,
  first_value(stop_reason) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by stop_reason nulls last) as stop_reason,
  first_value(condition_status_source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by condition_status_concept_id nulls last) as condition_status_source_value,
  first_value(condition_status_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by condition_status_concept_id nulls last) as condition_status_concept_id
from i
;

-- Copy of Observation except those that are in staging
drop table if exists observation_new;
create table observation_new as
select * from cdm.observation where observation_id not in (select event_id from staging where source_domain_id='Observation')
;

insert into observation_new(observation_id, person_id, observation_concept_id, observation_date, observation_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, observation_datetime, observation_source_value, observation_source_concept_id, value_as_number, value_as_concept_id, unit_concept_id, unit_source_value, value_as_string, qualifier_concept_id, qualifier_source_value)
with i as (
  select distinct
    person_id, --2
    coalesce(target_concept_id, concept_id) as concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as start_date, --4
    cast(start_datetime as timestamp) as start_datetime, --5
    type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    source_value, --10
    source_concept_id, --11
    value_as_number, --15
    coalesce(target_value_as_concept_id, value_as_concept_id) as value_as_concept_id, --16
    unit_concept_id, --17
    unit_source_value, --18
    value_as_string, --35
    qualifier_concept_id, --36
    qualifier_source_value --37
  from staging where coalesce(target_domain_id, source_domain_id)='Observation' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(condition_occurrence_id) from cdm.condition_occurrence) + row_number() over () as event_id,
  person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
  first_value(start_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by start_datetime nulls last) as start_datetime,
  first_value(source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_value,
  first_value(source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_concept_id,
  first_value(value_as_number) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by value_as_number nulls last) as value_as_number,
  first_value(value_as_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by value_as_concept_id nulls last) as value_as_concept_id,
  first_value(unit_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unit_concept_id nulls last) as unit_concept_id,
  first_value(unit_source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unit_concept_id nulls last) as unit_source_value,
  first_value(value_as_string) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by value_as_string nulls last) as value_as_string,
  first_value(qualifier_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by qualifier_concept_id nulls last) as qualifier_concept_id,
  first_value(qualifier_source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by qualifier_concept_id nulls last) as qualifier_source_value
from i
;

drop table if exists measurement_new;
create table measurement_new as
select * from cdm.measurement where measurement_id not in (select event_id from staging where source_domain_id='Measurement')
;
insert into measurement_new(measurement_id, person_id, measurement_concept_id, measurement_date, measurement_type_concept_id, provider_id, visit_occurrence_id, visit_detail_id, measurement_datetime, measurement_source_value, measurement_source_concept_id, value_as_number, value_as_concept_id, unit_concept_id, unit_source_value, unit_source_concept_id, measurement_time, operator_concept_id, range_low, range_high)
with i as (
  select distinct
    person_id, --2
    coalesce(target_concept_id, concept_id) as concept_id, -- this will replace the concept with the mapping
    cast(start_date as date) as start_date, --4
    cast(start_datetime as timestamp) as start_datetime, --5
    type_concept_id, --6
    provider_id, --7
    visit_occurrence_id, --8
    visit_detail_id, --9
    source_value, --10
    source_concept_id, --11
    value_as_number, --15
    value_as_concept_id, --16
    unit_concept_id, --17
    unit_source_value, --18
    unit_source_concept_id, --19 
    measurement_time, --28
    operator_concept_id, --29
    range_low, --30
    range_high --31
  from staging where coalesce(target_domain_id, source_domain_id)='Measurement' -- this will replace the domain with the corrected domain
)
select distinct
  (select max(measurement_id) from cdm.measurement) + row_number() over () as event_id,
  person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id,
  first_value(start_datetime) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by start_datetime nulls last) as start_datetime,
  first_value(source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_value,
  first_value(source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by source_concept_id nulls last) as source_concept_id,
  first_value(value_as_number) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by value_as_number nulls last) as value_as_number,
  first_value(value_as_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by value_as_concept_id nulls last) as value_as_concept_id,
  first_value(unit_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unit_concept_id nulls last) as unit_concept_id,
  first_value(unit_source_value) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unit_concept_id nulls last) as unit_source_value,
  first_value(unit_source_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by unit_source_concept_id nulls last) as unit_source_concept_id,
  first_value(measurement_time) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by measurement_time nulls last) as measurement_time,
  first_value(operator_concept_id) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by operator_concept_id nulls last) as operator_concept_id,
  first_value(range_low) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by range_low nulls last) as range_low,
  first_value(range_high) over (partition by person_id, concept_id, start_date, type_concept_id, provider_id, visit_occurrence_id, visit_detail_id order by range_high desc nulls last) as range_high -- taking the highest 
from i
;

-- clean up
drop table patch.mapping;
drop table patch.new_concept;
drop table patch.to_value;
drop table staging;

-----------------------------------------
set search_path='patch';
drop table condition_occurrence_new;
drop table device_exposure_new;
drop table drug_exposure_new;
drop table measurement_new;
drop table stop_concept;
