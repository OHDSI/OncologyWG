-- Valid standard
with tmp as (
select partner, sum("record_%") as res
from results.standard_summary_report
group by partner),
partners as (
  select distinct partner
  from results.patient
)
select partner, round((1 - coalesce(res, 0)) * 100, 2) as valid_standard
from partners
left join tmp using (partner)
order by partner;

-- Readiness
with sums as (
  select partner, coalesce(sum("record_%"), 0) as rec_perc, coalesce(sum("concept_%"), 0) as con_perc
  from results.standard_summary_report_cleaned
  group by partner
),
ready as (
  select partner, round((1 - rec_perc) * 100, 2) as readiness_rec,
  round((1 - con_perc) * 100, 2) as readiness_con
  from sums
)
select partner, coalesce(readiness_rec, 100.00) as readiness_rec, coalesce(readiness_con, 100.00) as readiness_con
from results.patient
left join ready using (partner)
order by partner;

-- Patient count and time windows
select partner, cnt as patient_count, to_char(coalesce(first_event, date('2000-01-01')), 'YYYY-MM-DD') as first_event,
to_char(coalesce(last_event, date('2000-01-01')), 'YYYY-MM-DD') as last_event,
to_char(coalesce(observation_start, date('2000-01-01')), 'YYYY-MM-DD') as observation_start,
to_char(coalesce(observation_end, date('2000-01-01')), 'YYYY-MM-DD') as observation_end
from results.patient
order by partner;

-- Mapping errors
with wrongs as (
  select partner, "record_%" as wrong_mapping
  from results.mapping_summary_report
  where critique = 'Wrong mapping'
),
needs as (
  select partner, "record_%" as needs_mapping
  from results.mapping_summary_report
  where critique = 'Needs mapping'
),
avail as (
  select partner, "record_%" as available
  from results.mapping_summary_report
  where critique = 'Mapping available'
)
select partner, round(coalesce(wrong_mapping, 0) * 100, 2) as wrong_mapping, 
round(coalesce(needs_mapping, 0) * 100, 2) as needs_mapping, round(coalesce(available, 0) * 100, 2) as available
from results.patient
left join wrongs using (partner)
left join needs using (partner)
left join avail using (partner)
order by partner;

-- Distribution of histology and topology
select * from results.histo_topo_percent order by partner;

-- Count metastases, grade and stage concepts
select * from results.met_grade_stage order by partner;

-- Genomic classes
with cats as (
  select distinct partner, concept_class_id 
  from results.genomic g 
  join prodv5.concept on g.standard=concept_id
  where concept_class_id <> 'Undefined'
),
concatenated as (
  select partner, STRING_AGG(concept_class_id, ', ') as classes
  from cats
  group by partner
)
select partner, coalesce(classes, 'None') as genomic_classes
from results.patient
left join concatenated using (partner)
order by partner;
