-- Average time between diagnosis and treatment
select e.cancer_type, e.is_metastatic,
avg(e.time_diagnosis_treatment_days) as avg_time_diagnosis_treatment_days
from
(select
c.concept_name as cancer_type,
case coalesce(reverse(substring(reverse(m.value_source_value) from 1
for position('@' in reverse(m.value_source_value)) - 1)), '@')
when '@' then 'Unknown' -- No records
when '0' then 'Non-Metastatic' -- No distant metastasis|Unknown if distant metastasis
when '00' then 'Non-Metastatic' -- No distant metastasis|Unknown if distant metastasis
when '05' then 'Non-Metastatic' -- No clinical or radiographic evidence of distant mets|- Tumor cells found in circulating blood, bone marrow or other distant lymph node tissue less than or equal to 0.2 mm
when '1' then 'Metastatic'
when '2' then 'Metastatic'
when '10' then 'Metastatic'
when '20' then 'Metastatic'
when '30' then 'Metastatic'
when '40' then 'Metastatic'
when '50' then 'Metastatic'
when '60' then 'Metastatic'
when '70' then 'Metastatic'
when '8' then 'Unknown' -- Unknown
when '9' then 'Unknown' -- Unknown
when '88' then 'Unknown' -- Death certificate only
when '99' then 'Unknown' -- Unknwon
else 'Unknown' end
as is_metastatic,
DATE_PART('day', et.episode_start_datetime - ed.episode_start_datetime) as time_diagnosis_treatment_days
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
) as e
where e.time_diagnosis_treatment_days is not null
group by e.cancer_type, e.is_metastatic;
