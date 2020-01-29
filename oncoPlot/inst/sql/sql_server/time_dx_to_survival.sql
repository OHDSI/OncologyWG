 -- Survival from diagnosis, record level
select
ed.person_id,
c.concept_name as cohort_cols,
meas.is_metastatic,
case WHEN dth.death_datetime is null then 1 else 0 end as event_col,
DATEDIFF(month, ed.episode_start_datetime, coalesce(dth.death_datetime, op.last_followup_date)) as survival_time_col
from @cdmSchema.episode ed
left join @cdmSchema.person p
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.person_id = p.person_id
left join
( select distinct person_id , MAX(death_datetime) death_datetime
from @cdmSchema.death
group by person_id
)  dth
on p.person_id = dth.person_id
left join
(select max(observation_period_end_date) as last_followup_date, person_id
from @cdmSchema.observation_period
group by person_id
)  op
on ed.person_id = op.person_id
join @cdmSchema.concept_relationship cr1
on ed.episode_object_concept_id = cr1.concept_id_2
and cr1.relationship_id = 'Maps to'
left join @cdmSchema.concept_relationship cr2
on cr1.concept_id_1 = cr2.concept_id_1
and cr2.relationship_id = 'ICDO to Schema'
join @cdmSchema.concept c
on cr2.concept_id_2 = c.concept_id
left join
(
  SELECT modifier_of_event_id
		,CASE
			WHEN metastatic > 0 THEN 'Metastatic'
			WHEN metastatic = 0 AND nonmeta > 0 THEN 'Non-Metastatic'
			ELSE 'Unknown'
		END as is_metastatic
 FROM
 (
  SELECT modifier_of_event_id
		,COUNT(CASE WHEN value_source_value IN ('1','2') THEN 1 END) metastatic
		,COUNT(CASE WHEN value_source_value = 0  THEN 1 END ) nonmeta
 FROM @cdmSchema.measurement
 WHERE modifier_of_field_concept_id = 1000000003 -- 'epsiode.episode_id'
 AND measurement_concept_id
 IN (
 35918335 -- EOD Mets
,35918581 -- Mets at DX-Bone
,35918692 -- Mets at DX-Brain
,35918491 -- Mets at DX-Distant LN
,35918290 -- Mets at DX-Liver
,35918559 -- Mets at DX-Lung
,35918527 -- Mets at DX-Other
 )
 GROUP BY modifier_of_event_id
 ) x
 ) meas
 on ed.episode_id = meas.modifier_of_event_id
