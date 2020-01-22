-- Survival from diagnosis, record level
SET search_path TO omop, public;

select
ed.episode_id,
ed.person_id,
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
case dt.death_datetime is null when true then 1 else 0 end as vital_status,
round(DATE_PART('day', coalesce(dt.death_datetime, op.last_followup_date) - ed.episode_start_datetime)/30)
as survival_from_diagnosis_months
from episode ed
left join person p
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = p.person_id
LEFT JOIN death dt             ON p.person_id = dt.person_id
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
;