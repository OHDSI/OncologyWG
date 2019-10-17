--1.	ETL of diagnosis and diagnostic modifiers into CONDITION_OCCURRENCE& MEASUREMENT.

--a.	Ingest condition occurrence
Insert into condition_occurrence
(condition_occurrence_id,
person_id,
condition_start_datetime,
condition_concept_id,
condition_type_concept_id,
condition_source_value,
condition_source_concept_id)
select
row_number() over() as condition_occurrence_id, -- use your sequence generator instead
s.person_id as person_id,
CASE WHEN length(s.naaccr_item_value ) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END as  condition_start_datetime,
c2.concept_id as condition_concept_id,
32534 as condition_type_concept_id, -- Tumor registry concept
s.histology_site as condition_source_value,
c1.concept_id as condition_source_concept_id
from data_source as s
join concept as c2 on c2.standard_concept ='S'
join concept_relationship as ra on ra.concept_id_2 = c2.concept_id and ra.relationship_id = 'Maps to'
join concept as c1 on c1.concept_id = ra.concept_id_1
and c1.concept_code = s.histology_site
and c1.vocabulary_id ='ICDO3'
where s.naaccr_item_number = '390'

--b.	Ingest first disease occurrence modifier
Insert into measurement
(measurement_id,
person_id,
measurement_datetime,
measurement_concept_id,
measurement_type_concept_id,
measurement_source_value,
modifier_of_event_id,
modifier_field_concept_id)
select distinct
row_number() over() as measurement_id, -- use your sequence generator instead
fco.*
from
(select distinct
co.person_id as person_id,
co.condition_start_datetime as measurement_datetime,
32528 as measurement_concept_id, -- Disease First Occurrence concept
32534 as measurement_type_concept_id, -- Tumor registry concept
'First disease occurrence' as measurement_source_value,
co.condition_occurrence_id as modifier_of_event_id,
1147127 as modifier_field_concept_id -- condition_occurrence.condition_occurrence_id concept
from data_source as s
join condition_occurrence as co on s.person_id = co.person_id
and CASE WHEN length(s.naaccr_item_value ) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END
= co.condition_start_datetime
and s.naaccr_item_number = '390'
and co.condition_source_value = s.histology_site) as fco

--c.	Ingest diagnostic modifiers with values as concepts
Insert into measurement
(measurement_id,
person_id,
measurement_datetime,
measurement_concept_id,
value_as_concept_id,
measurement_type_concept_id,
measurement_source_value,
measurement_source_concept_id,
value_source_value,
modifier_of_event_id,
modifier_field_concept_id)

select row_number() over() as measurement_id,
cm.*
from (
select distinct
s.person_id as person_id
, CASE WHEN length(sd.naaccr_item_value ) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END as measurement_datetime
, cr2.concept_id_2 as measurement_concept_id
, c3.concept_id as value_as_concept_id
, 32534 as measurement_type_concept_id -- Tumor registry concept
, c2.concept_code as measurement_source_value
, c2.concept_id as measurement_source_concept_id
, c3.concept_code as value_source_value
, co.condition_occurrence_id
, 1147127 as modifier_field_concept_id -- condition_occurrence.condition_occurrence_id concept
FROM data_source AS s
-- Getting schema
JOIN concept d
ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
JOIN concept_relationship cr1
ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
JOIN concept AS c1
ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
-- Limiting to schemas that have only one-to-many relationships with diagnoses. This is to avoid ambiquous NAACCR item/values per diagnosis
JOIN (
SELECT
c2.concept_id as schema_concept_id
from concept c1
join concept_relationship cr
on c1.concept_id = cr.concept_id_1 and vocabulary_id='ICDO3'
join concept c2
on cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
join (
SELECT c1.concept_id, c1.concept_code, count(*) as total
from concept c1
join concept_relationship cr
on c1.concept_id = cr.concept_id_1 and c1.vocabulary_id='ICDO3'
join concept c2
on cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
--and c2.vocabulary_id = 'NAACR'
group by c1.concept_id, c1.concept_code
having count(*) = 1
) as dupl
on c1.concept_id = dupl.concept_id
group by c2.concept_id) AS sincl
ON c1.concept_id = sincl.schema_concept_id

---- Getting source variables
JOIN concept AS c2
ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number)
---- Getting standard variables
join concept_relationship cr2
on c2.concept_id = cr2.concept_id_1 and cr2.relationship_id = 'Maps to'
-- Constrain to the following NAACCRR variable categories: Histology, Primary Site
join concept_relationship cc
on c2.concept_id = cc.concept_id_1 and cc.relationship_id = 'Has parent item' and cc.concept_id_2 = 35918916
-- and (cc.concept_id_2 = 35918916 or cc.concept_id_2 = 35918588) -- that's how it was supposed to be coded, but this relationship has to be corrected and it slows down the query
-- Identify numeric type variables
left join concept_relationship cn
on c2.concept_id = cn.concept_id_1 and cn.relationship_id = 'Has type' and cn.concept_id_2 = 32676
---- Getting permissible value
JOIN concept AS c3
ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
---- Getting date
join concept_relationship crd
on c2.concept_id = crd.concept_id_1 and crd.relationship_id = 'Variable has date'
join concept cd on crd.concept_id_2 = cd.concept_id
join data_source as sd
on s.person_id = sd.person_id and sd.naaccr_item_number = cd.concept_code
---- Getting condition_occurrence record
join
(select
co.person_id
, co.condition_occurrence_id
, s.record_id
from
(select
co.person_id
, co.condition_occurrence_id
, date(co.condition_start_datetime) as condition_start_date
, co.condition_source_value
, rank () OVER (PARTITION BY co.person_id ORDER BY co.person_id, co.condition_occurrence_id) AS occurrence_number
FROM condition_occurrence co
where co.condition_type_concept_id = 32534) as co
join
(select
s.person_id
, s.record_id
, CASE WHEN length(s.naaccr_item_value ) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END as condition_start_date
, s.histology_site
, rank () OVER (PARTITION BY s.person_id ORDER BY s.person_id, s.record_id) AS occurrence_number
FROM data_source AS s
where s.naaccr_item_number = '390'
) as s
on co.person_id = s.person_id
and co.occurrence_number = s.occurrence_number
and co.condition_source_value = s.histology_site) as co
on co.person_id = s.person_id
and co.record_id = s.record_id
where cn.concept_id_1 is null -- excluding numeric types
) as cm


--d.	Ingest diagnostic modifiers with values as number
Insert into measurement
(measurement_id,
person_id,
measurement_datetime,
measurement_concept_id,
value_as_concept_id,
value_as_number,
unit_concept_id,
operator_concept_id,
measurement_type_concept_id,
measurement_source_value,
measurement_source_concept_id,
value_source_value,
modifier_of_event_id,
modifier_field_concept_id)
select row_number() over() as measurement_id, -- use your sequence generator instead
cm.*
from (
select distinct
 s.person_id as person_id
, CASE WHEN length(sd.naaccr_item_value ) = 8 THEN to_date(sd.naaccr_item_value,'YYYYMMDD') ELSE NULL END as measurement_datetime
, c2.concept_id as measurement_concept_id
, c3.concept_id as value_as_concept_id
, case when c3.concept_id is null then cast(s.naaccr_item_value as integer) else cn.value_as_number end as value_as_number
, case when c3.concept_id is null then cru.concept_id_2 else cn.unit_concept_id end as measurement_unit_id
, case when c3.concept_id is null then null else cn.operator_concept_id end as operator_concept_id
, 32534 as measurement_type_concept_id -- Tumor registry concept
, c2.concept_code as measurement_source_value
, c2.concept_id as measurement_source_concept_id
, case when c3.concept_id is null then s.naaccr_item_value else c3.concept_code end as value_source_value
, co.condition_occurrence_id
, 1147127 as modifier_field_concept_id -- condition_occurrence.condition_occurrence_id concept
FROM data_source AS s
-- Getting schema
JOIN concept d
ON d.vocabulary_id = 'ICDO3' AND d.concept_code = s.histology_site
JOIN concept_relationship cr1
ON d.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'ICDO to Schema'
JOIN concept AS c1
ON cr1.concept_id_2 = c1.concept_id AND c1.vocabulary_id = 'NAACCR'
-- Limiting to schemas that have only one-to-many relationships with diagnoses. This is to avoid ambiquous NAACCR item/values per diagnosis
JOIN (
SELECT
c2.concept_id as schema_concept_id
from concept c1
join concept_relationship cr
on c1.concept_id = cr.concept_id_1 and vocabulary_id='ICDO3'
join concept c2
on cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
join (
SELECT c1.concept_id, c1.concept_code, count(*) as total
from concept c1
join concept_relationship cr
on c1.concept_id = cr.concept_id_1 and c1.vocabulary_id='ICDO3'
join concept c2
on cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
--and c2.vocabulary_id = 'NAACR'
group by c1.concept_id, c1.concept_code
having count(*) = 1
) as dupl
on c1.concept_id = dupl.concept_id
group by c2.concept_id) AS sincl
ON c1.concept_id = sincl.schema_concept_id
-- Getting variable
JOIN concept AS c2
ON c2.vocabulary_id = 'NAACCR' AND (c2.concept_code = s.naaccr_item_number OR c2.concept_code = c1.concept_code || '@' || s.naaccr_item_number)
-- Constraining to numeric concepts only
JOIN concept_relationship AS crn
on c2.concept_id = crn.concept_id_1 and crn.relationship_id = 'Has type'
and crn.concept_id_2 = 32676 -- numeric
-- Constraining to the following NAACCRR variable categories: Histology, Primary Site
join concept_relationship cc
on c2.concept_id = cc.concept_id_1 and cc.relationship_id = 'Has parent item' and cc.concept_id_2 = 35918916
-- and (cc.concept_id_2 = 35918916 or cc.concept_id_2 = 35918588) -- that's how it was supposed to be coded, but this relationship has to be corrected and it slows down the query
-- Getting units if exist
left JOIN concept_relationship AS cru
on c2.concept_id = cru.concept_id_1 and cru.relationship_id = 'Has unit'
-- Getting permissible value for ranges
left JOIN concept AS c3
ON c3.vocabulary_id = 'NAACCR' AND (c3.concept_code = s.naaccr_item_number ||  '@' || s.naaccr_item_value OR c3.concept_code = c1.concept_code || '@'  || s.naaccr_item_number  || '@'  || s.naaccr_item_value)
left JOIN concept_numeric AS cn
ON c3.concept_id = cn.concept_id
---- Getting date
join concept_relationship crd
on c2.concept_id = crd.concept_id_1 and crd.relationship_id = 'Variable has date'
join concept cd on crd.concept_id_2 = cd.concept_id
join data_source as sd
on s.person_id = sd.person_id and sd.naaccr_item_number = cd.concept_code
---- Getting condition_occurrence record
join
(select
co.person_id
, co.condition_occurrence_id
, s.record_id
from
(select
co.person_id
, co.condition_occurrence_id
, date(co.condition_start_datetime) as condition_start_date
, co.condition_source_value
, rank () OVER (PARTITION BY co.person_id ORDER BY co.person_id, co.condition_occurrence_id) AS occurrence_number
FROM condition_occurrence co
where co.condition_type_concept_id = 32534) as co
join
(select
s.person_id
, s.record_id
, CASE WHEN length(s.naaccr_item_value ) = 8 THEN to_date(s.naaccr_item_value,'YYYYMMDD') ELSE NULL END as condition_start_date
, s.histology_site
, rank () OVER (PARTITION BY s.person_id ORDER BY s.person_id, s.record_id) AS occurrence_number
FROM data_source AS s
where s.naaccr_item_number = '390'
) as s
on co.person_id = s.person_id
and co.occurrence_number = s.occurrence_number
and co.condition_source_value = s.histology_site) as co
on co.person_id = s.person_id
and co.record_id = s.record_id
) as cm





--2.	Post-ETL of disease into EPISODE, EPISODE_EVENT, and MEASUREMENT
-- This part of ETL completely depends on episode derivation algorithm and will vary from case to case. The ETL below will work for the first cancer occurrence derived from cancer registry data

--a.	Ingest first disease occurrence in EPISODE
Insert into episode
(episode_id,
person_id,
episode_start_datetime,
episode_end_datetime,
episode_concept_id,
episode_object_concept_id,
episode_type_concept_id,
episode_source_value)
select row_number() over() as episode_id
, co.person_id as person_id
, co.condition_start_datetime as episode_start_datetime
, now()
, 32528 as episode_concept_id -- Disease First Occurrence concept
, co.condition_concept_id as episode_object_concept_id
, 32534 as episode_type_concept_id  -- Tumor registry concept
, co.condition_occurrence_id
From condition_occurrence as co
join measurement as m on co.condition_occurrence_id = m.modifier_of_event_id
and m.modifier_field_concept_id = 1147127  condition_occurence.condition_occurrence_id
and m.measurement_concept_id = 32528 -- First disease occurrence concept

--b.	Ingest connection between EPISODE record and CONDITION_OCCURRENCE record
Insert into episode_event
(episode_id,
event_id,
event_field_concept_id)
select e.episode_id as episode_id
, cast(e.episode_source_value as integer) as episode_event_id -- this may be different depending on the derivation of episode
, 1147127 as episode_event_field_concept_id -- condition_occurrence.condition_occurrence_id concept
From episode as e


--c.	Ingest a clean set of EPISODE modifiers into MEASUREMENT
Insert into measurement
(measurement_id,
person_id,
measurement_datetime,
measurement_concept_id,
value_as_concept_id,
value_as_number,
unit_concept_id,
operator_concept_id,
measurement_type_concept_id,
measurement_source_value,
measurement_source_concept_id,
value_source_value,
modifier_of_event_id,
modifier_field_concept_id)
select row_number() over() as measurement_id,
m.person_id,
m.measurement_datetime,
m.measurement_concept_id,
m.value_as_concept_id,
m.value_as_number,
m.unit_concept_id,
m.operator_concept_id,
m.measurement_type_concept_id,
m.measurement_source_value,
m.measurement_concept_id,
m.value_source_value,
e.episode_id ,
1000000003 as episode_event_field_concept_id -- episode.episode_id concept to be created
From episode as e
join episode_event as ee on e.episode_id = ee.episode_id
join condition_occurrence as co on ee.event_id = co.condition_occurrence_id
and ee.event_field_concept_id = 1147127
join measurement as m on co.condition_occurrence_id = m.modifier_of_event_id
and m.modifier_field_concept_id = 1147127

