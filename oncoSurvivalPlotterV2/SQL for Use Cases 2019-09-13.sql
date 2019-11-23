-- Time between diagnosis and treatment, record level
select person_id, cancer_type, 
case sum(is_metastatic)
when 1 then 'Metastatic'
when 0 then 'Non-Metastatic'
else 'Unknown'
end as is_metastatic,
time_daignosis_treatment_days
from (
select 
ed.person_id as person_id,
c.concept_name as cancer_type,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end 
as is_metastatic,
DATE_PART('day', et.episode_start_datetime - ed.episode_start_datetime) as time_daignosis_treatment_days
from episode ed
left join 
(select min(episode_start_datetime) as episode_start_datetime, episode_parent_id
from episode
where episode_concept_id in (32531, 32532)
and episode_parent_id is not null
group by episode_parent_id
) as et
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.episode_id = et.episode_parent_id
join concept_relationship cr1
on ed.episode_object_concept_id = cr1.concept_id_2
and cr1.relationship_id = 'Maps to'
left join concept_relationship cr2
on cr1.concept_id_1 = cr2.concept_id_1
and cr2.relationship_id = 'ICDO to Schema'
join concept c
on cr2.concept_id_2 = c.concept_id
left join measurement m
on ed.episode_id = m.modifier_of_event_id
and m.modifier_of_field_concept_id = 1000000003 -- 'epsiode.episode_id'
and m.measurement_concept_id 
-- NAACCR items for metastases. Does not include site-specific items.
in (
35918335 -- EOD Mets
,35918581 -- Mets at DX-Bone
,35918692 -- Mets at DX-Brain
,35918491 -- Mets at DX-Distant LN
,35918290 -- Mets at DX-Liver
,35918559 -- Mets at DX-Lung
,35918527 -- Mets at DX-Other
)
group by ed.person_id,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end,
c.concept_name,
DATE_PART('day', et.episode_start_datetime - ed.episode_start_datetime) 
) as met
group by person_id, cancer_type, time_daignosis_treatment_days



-- Average time between diagnosis and treatment
select e.cancer_type, e.is_metastatic, 
avg(e.time_daignosis_treatment_days) as avg_time_diagnosis_treatment_days
from
(select person_id, cancer_type, 
case sum(is_metastatic)
when 1 then 'Metastatic'
when 0 then 'Non-Metastatic'
else 'Unknown'
end as is_metastatic,
time_daignosis_treatment_days
from (
select 
ed.person_id as person_id,
c.concept_name as cancer_type,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end 
as is_metastatic,
DATE_PART('day', et.episode_start_datetime - ed.episode_start_datetime) as time_daignosis_treatment_days
from episode ed
left join 
(select min(episode_start_datetime) as episode_start_datetime, episode_parent_id
from episode
where episode_concept_id in (32531, 32532)
and episode_parent_id is not null
group by episode_parent_id
) as et
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.episode_id = et.episode_parent_id
join concept_relationship cr1
on ed.episode_object_concept_id = cr1.concept_id_2
and cr1.relationship_id = 'Maps to'
left join concept_relationship cr2
on cr1.concept_id_1 = cr2.concept_id_1
and cr2.relationship_id = 'ICDO to Schema'
join concept c
on cr2.concept_id_2 = c.concept_id
left join measurement m
on ed.episode_id = m.modifier_of_event_id
and m.modifier_of_field_concept_id = 1000000003 -- 'epsiode.episode_id'
and m.measurement_concept_id 
-- NAACCR items for metastases. Does not include site-specific items.
in (
35918335 -- EOD Mets
,35918581 -- Mets at DX-Bone
,35918692 -- Mets at DX-Brain
,35918491 -- Mets at DX-Distant LN
,35918290 -- Mets at DX-Liver
,35918559 -- Mets at DX-Lung
,35918527 -- Mets at DX-Other
)
group by ed.person_id,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end,
c.concept_name,
DATE_PART('day', et.episode_start_datetime - ed.episode_start_datetime) 
) as met
group by person_id, cancer_type, time_daignosis_treatment_days
) as e
where e.time_daignosis_treatment_days is not null
group by e.cancer_type, e.is_metastatic


-- Survival from diagnosis, record level
select person_id, cancer_type, 
case sum(is_metastatic)
when 1 then 'Metastatic'
when 0 then 'Non-Metastatic'
else 'Unknown'
end as is_metastatic,
vital_status, 
survival_from_diagnosis_months
from (
select 
ed.person_id as person_id,
c.concept_name as cancer_type,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end 
as is_metastatic,
case p.death_datetime is null when true then 0 else 1 end as vital_status,
round(DATE_PART('day', coalesce(p.death_datetime, op.last_followup_date) - ed.episode_start_datetime)/30) 
as survival_from_diagnosis_months
from episode ed
left join person p 
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = p.person_id
left join 
(select max(observation_period_end_date) as last_followup_date, person_id
from observation_period
group by person_id
) as op
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = op.person_id
join concept_relationship cr1
on ed.episode_object_concept_id = cr1.concept_id_2
and cr1.relationship_id = 'Maps to'
left join concept_relationship cr2
on cr1.concept_id_1 = cr2.concept_id_1
and cr2.relationship_id = 'ICDO to Schema'
join concept c
on cr2.concept_id_2 = c.concept_id
left join measurement m
on ed.episode_id = m.modifier_of_event_id
and m.modifier_of_field_concept_id = 1000000003 -- 'epsiode.episode_id'
and m.measurement_concept_id 
-- NAACCR items for metastases. Does not include site-specific items.
in (
35918335 -- EOD Mets
,35918581 -- Mets at DX-Bone
,35918692 -- Mets at DX-Brain
,35918491 -- Mets at DX-Distant LN
,35918290 -- Mets at DX-Liver
,35918559 -- Mets at DX-Lung
,35918527 -- Mets at DX-Other
)
group by ed.person_id,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end,
c.concept_name,
case p.death_datetime is null when true then 0 else 1 end,
round(DATE_PART('day', coalesce(p.death_datetime, op.last_followup_date) - ed.episode_start_datetime)/30) 
) as met
group by person_id, cancer_type, vital_status, survival_from_diagnosis_months



-- Average survival from diagnosis(only for deceased patients)
select e.cancer_type, e.is_metastatic, 
avg(e.survival_from_diagnosis_months) as avg_survival_from_diagnosis_months
from
(
select person_id, cancer_type, 
case sum(is_metastatic)
when 1 then 'Metastatic'
when 0 then 'Non-Metastatic'
else 'Unknown'
end as is_metastatic,
vital_status, 
survival_from_diagnosis_months
from (
select 
ed.person_id as person_id,
c.concept_name as cancer_type,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end 
as is_metastatic,
case p.death_datetime is null when true then 0 else 1 end as vital_status,
round(DATE_PART('day', coalesce(p.death_datetime, op.last_followup_date) - ed.episode_start_datetime)/30) 
as survival_from_diagnosis_months
from episode ed
left join person p 
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = p.person_id
left join 
(select max(observation_period_end_date) as last_followup_date, person_id
from observation_period
group by person_id
) as op
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = op.person_id
join concept_relationship cr1
on ed.episode_object_concept_id = cr1.concept_id_2
and cr1.relationship_id = 'Maps to'
left join concept_relationship cr2
on cr1.concept_id_1 = cr2.concept_id_1
and cr2.relationship_id = 'ICDO to Schema'
join concept c
on cr2.concept_id_2 = c.concept_id
left join measurement m
on ed.episode_id = m.modifier_of_event_id
and m.modifier_of_field_concept_id = 1000000003 -- 'epsiode.episode_id'
and m.measurement_concept_id 
-- NAACCR items for metastases. Does not include site-specific items.
in (
35918335 -- EOD Mets
,35918581 -- Mets at DX-Bone
,35918692 -- Mets at DX-Brain
,35918491 -- Mets at DX-Distant LN
,35918290 -- Mets at DX-Liver
,35918559 -- Mets at DX-Lung
,35918527 -- Mets at DX-Other
)
group by ed.person_id,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1 
for position('@' in reverse(m.value_source_value)) - 1)), '@') 
when '@' then null -- No records
when '0' then 0 -- No distant metastasis|Unknown if distant metastasis
when '00' then 0 -- No distant metastasis|Unknown if distant metastasis
when '05' then 0 -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 1 
when '10' then 1 
when '20' then 1 
when '30' then 1 
when '40' then 1 
when '50' then 1 
when '60' then 1 
when '70' then 1 
when '8' then null -- Unknown
when '9' then null -- Unknown
when '88' then null -- Death certificate only
when '99' then null -- Unknwon
else null end,
c.concept_name,
case p.death_datetime is null when true then 0 else 1 end,
round(DATE_PART('day', coalesce(p.death_datetime, op.last_followup_date) - ed.episode_start_datetime)/30) 
) as met
group by person_id, cancer_type, vital_status, survival_from_diagnosis_months
) as e
where e.vital_status = 1
group by e.cancer_type, e.is_metastatic