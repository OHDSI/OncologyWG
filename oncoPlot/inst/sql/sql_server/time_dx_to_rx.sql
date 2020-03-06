-- Time between diagnosis and treatment, record level
select
ed.person_id,
c.concept_name as cancer_type,
COALESCE(meas.is_metastatic, 'Unknown') as cohort_cols,
DATEDIFF(day, ed.episode_start_datetime, et.episode_start_datetime) as time_to_rx_col
from @cdmSchema.episode ed
inner join
(select min(episode_start_datetime) as episode_start_datetime, episode_parent_id
from @cdmSchema.episode
where episode_concept_id in (32531, 32532)
and episode_parent_id is not null
group by episode_parent_id
) as et
on ed.episode_concept_id = 32528 -- first disease occurrence
and ed.episode_id = et.episode_parent_id
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
		,COUNT(CASE WHEN value_source_value = '0'  THEN 1 END ) nonmeta
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
