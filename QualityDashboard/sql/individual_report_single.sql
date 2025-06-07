/* uses placeholders
   __schema__ - the schema containing the results from the user
   __cdm_schema__ - the schema containing the vocabulary tables (concept, etc.)
   __partner_name__ - the name of the data partner to calculate results for
*/

-- update database_summary for this partner
-- used to be "Database summary.txt"
delete from __schema__.database_summary
where partner = '__partner_name__';

insert into __schema__.database_summary
select partner, cnt as size, general, genomic, episodes 
from __schema__.patient
join (select partner, count(*) as general from __schema__.general group by partner) using(partner) 
left join (select partner, count(*) as genomic from __schema__.genomic group by partner) using(partner) 
left join (select partner, count(*) as episodes from __schema__.episodes group by partner) using(partner) 
where partner = '__partner_name__'
group by partner, cnt, general, genomic, episodes;

delete from __schema__.general_cleaned
where partner = '__partner_name__';

insert into __schema__.general_cleaned
with replace_null as (
  -- This makes sure null in standard is joined as 0 (which is in white_list).
  select partner, domain, source, coalesce(standard, 0) as standard, cnt
  from __schema__.general
)
select g.*
from replace_null g
join patch.white_list on concept_id = standard
where partner = '__partner_name__';

-- Domain weight (# records per domain) report.
-- used to be "Domain weights.txt"
delete from __schema__.domain_weights
where partner = '__partner_name__';

insert into __schema__.domain_weights
with cnts as ( -- total number of records per partner
  select partner, sum(cnt) as t_records from __schema__.general 
  where partner = '__partner_name__'
  group by partner
)
select partner, domain, records, round(records*1.0/t_records, 4) as "records_%"
from (
  select partner, case domain 
      when 'i' then 'Episode'
      when 'd' then 'Drug'
      when 'e' then 'Device'
      when 'p' then 'Procedure'
      when 'c' then 'Condition'
      when 'o' then 'Observation'
      when 'm' then 'Measurement'
      when 'v' then 'Meas Value'
      else ''
    end as domain, 
    sum(cnt) as records
  from __schema__.general
  where partner = '__partner_name__'
  group by partner, domain
) a join cnts using(partner)
order by 1, 4 desc;


-- Rolled-up tumor types report
-- used to be "Rolled-up tumor types.txt"
delete from __schema__.rolled_up_tumor_types
where partner = '__partner_name__';

drop table if exists temp_tumor_types;

create temp table temp_tumor_types as
with cancer_type(p, t_name, concept_id) as ( -- ancestors with tumor types, roughly at the level of ICD10, but in SNOMED
values -- the field "p" indicates the priority in case a tumor rolls up to more than one category
(1, 'Esophagus', 4181343),
(1, 'Esophagus', 28109),
(2, 'Stomach', 443387),
(2, 'Stomach', 200974), -- cis
(3, 'Small intestine', 443397),
(3, 'Small intestine', 4245666), -- cis
(4, 'Large intestine', 443396),
(4, 'Large intestine', 80045), -- anus
(4, 'Large intestine', 4244501), -- cis
(4, 'Large intestine', 78110), -- cis anus
(5, 'Liver', 4246127),
(6, 'Biliary tract', 4181345),
(7, 'Pancreas', 4180793),
(8, 'Head and neck', 4114222),
(9, 'Lung and respiratory tract', 40493428),
(9, 'Lung and respiratory tract', 4113116),
(10, 'Thymus', 36673515),
(11, 'Mesothelioma', 4116069),
(12, 'Kaposi sarcoma', 434584),
(13, 'Thyroid', 4178976),
(14, 'Melanoma', 4162276),
(15, 'Skin', 444209),
(16, 'Adrenal gland', 4181328),
(18, 'Meninges', 4177240),
(19, 'Breast', 81251),
(20, 'Brain', 443588),
(21, 'CNS', 4155285),
(22, 'Nervous system', 4157331),
(23, 'Endocrine', 4156115),
(24, 'Kidney', 196653),
(25, 'Ovary', 4181351),
(26, 'Placenta', 36617597),
(27, 'Prostate', 4163261),
(28, 'Renal pelvis', 4181357),
(29, 'T-cell or NK-cell', 4227653),
(30, 'Follicular non-Hodgkin''s', 4147411),
(31, 'Diffuse non-Hodgkin''s', 4003830),
(32, 'Multiple myeloma', 437233),
(33, 'Lymphoid leukemia', 132853),
(34, 'Myeloid leukemia', 140666),
(35, 'Monocytic leukemia', 321526),
(36, 'Bladder', 197508),
(36, 'Bladder', 192855), --cis
(37, 'Cervix', 198984),
(37, 'Cervix', 194611),
(38, 'Uterus', 197230),
(39, 'Urinary system', 4169598),
(39, 'Urinary system', 81247), -- cis
(40, 'Female genital', 4177244),
(40, 'Female genital', 192577),
(40, 'Female genital', 4178959), -- vulva
(41, 'Male genital', 4181487),
(41, 'Male genital', 196068),
(42, 'Immunoproliferative', 4003834),
(43, 'Hodgkin''s', 4038835),
(44, 'Other Non-Hodgkin''s', 4038838),
(45, 'Other Leukemia', 317510),
(46, 'Lymphoid hemopoietic', 4147164),
(47, 'Mediastinum', 4181484),
(48, 'Peritoneum', 4089665),
(48, 'Peritoneum', 4180794), -- retroperitoneum
(49, 'Bone', 443564),
(49, 'Bone', 40482784), -- skeletal system
(50, 'Cartilage', 444203),
(51, 'Soft tissue', 4153882),
(51, 'Soft tissue', 40488964), -- connective tissue
(52, 'Unknown origin', 4114221)
--(52, 'Unknown origin', 433435)
),
c_types as (
  select distinct partner, standard, first_value(t_name) over (partition by standard order by p) as cancer_type, cnt
  from __schema__.general
  join (select descendant_concept_id as standard, t_name, p from __cdm_schema__.concept_ancestor join cancer_type on concept_id=ancestor_concept_id) ancestor using(standard)
  where domain='c'
  and partner = '__partner_name__'
),
exist_types as ( -- to report on the same tumor types for each partner, even if it doesn't have each.
  select distinct cancer_type from c_types
),
cst_summed as ( -- sum up records and force into report all partners and tumor types 
  select partner, cancer_type, sum(cnt) as records
  from c_types
  group by partner, cancer_type
),
conditions as ( -- instead of total number of records per partner only those in the Condition table
  select partner, sum(cnt) as t_records
  from __schema__.general 
  where domain='c'
  group by partner
)
select partner, cancer_type, records, round(records*1.0/t_records, 4) as "record_%" 
from cst_summed join conditions using(partner)
where partner = '__partner_name__'
order by 1, 3 desc;

-- prepare a bunch of temp tables for source, mapping and standard concept reports
-- list of vocabularies that are kosher for a domain
drop table if exists vocab_domain;
create temp table vocab_domain as
with vocab_domain(vocabulary_id, domain_id) as (
  values
    ('Cancer Modifier', 'Measurement'),
    ('CDT', 'Device'),
    ('CDT', 'Procedure'),
    ('CPT4', 'Measurement'),
    ('CPT4', 'Observation'),
    ('CPT4', 'Procedure'),
    ('CVX', 'Drug'),
    ('HCPCS', 'Device'),
    ('HCPCS', 'Measurement'),
    ('HCPCS', 'Observation'),
    ('HCPCS', 'Procedure'),
    ('HemOnc', 'Episode'),
    ('ICD10', 'Condition'),
    ('ICD10PCS', 'Procedure'),
    ('ICD9Proc', 'Procedure'),
    ('ICDO3', 'Condition'),
    ('ICDO3', 'Observation'),
    ('LOINC', 'Meas Value'),
    ('LOINC', 'Measurement'),
    ('LOINC', 'Observation'),
    ('OMOP Extension', 'Observation'),
    ('OMOP Genomic', 'Measurement'),
    ('OPCS4', 'Procedure'),
    ('RxNorm', 'Drug'),
    ('RxNorm Extension', 'Drug'),
    ('SNOMED', 'Condition'),
    ('SNOMED', 'Device'),
    ('SNOMED', 'Meas Value'),
    ('SNOMED', 'Measurement'),
    ('SNOMED', 'Observation'),
    ('SNOMED', 'Procedure')
)
select * from vocab_domain;

-- resolution of domain abbreviation in query (to save space)
drop table if exists d;
create temp table d as
with d(domain, is_domain) as (
  values
    ('i', 'Episode'),
    ('d', 'Drug'),
    ('e', 'Device'),
    ('p', 'Procedure'),
    ('c', 'Condition'),
    ('o', 'Observation'),
    ('m', 'Measurement'),
    ('v', 'Meas Value')
)
select * from d;

-- all source concepts and their correct mappings from concept_relationship
drop table if exists should;
create temp table should as 
with should as (
  select distinct source
  from __schema__.general
  join __cdm_schema__.concept_relationship on concept_id_1=source and invalid_reason is null and relationship_id in ('Maps to', 'Maps to value') and concept_id_1!=concept_id_2
)
select * from should;

-- source-standard pairs that also exist as "Maps to" relationships
drop table if exists ismap;
create temp table ismap as 
with ismap as (
  select distinct source, standard
  from __schema__.general
  join __cdm_schema__.concept_relationship on concept_id_1=source and concept_id_2=standard and invalid_reason is null and relationship_id='Maps to'
    and concept_id_1!=concept_id_2
)
select * from ismap;

-- critique standard concepts
drop table if exists crit_sta;
create temp table crit_sta as
with crit_sta as (
  select partner, 'Standard' as concept, concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable') then 'Flavor of NULL'
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_grade) then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_stage) then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_met) then 'Invalid met or node'
      when vocab_domain.vocabulary_id is null then 'Wrong vocab for domain'
      when loincvar is not null then 'Wrong LOINC postcoordination'
      when is_domain!=domain_id then 'Wrong domain table'
      when is_domain='Meas Value' then 'Meas Value overloaded'
      when standard_concept is null then 'Not standard concept'
      else null 
    end as critique, 
    records
  from (select partner, standard, is_domain, sum(cnt) as records from __schema__.general join d using(domain) group by partner, standard, is_domain) as general
  join __cdm_schema__.concept on concept_id=standard
-- see if LOINC value, which needs to be pre-coordinated
  left join (select distinct concept_id_1, 1 as loincvar from __cdm_schema__.concept_relationship join __cdm_schema__.concept on concept_id=concept_id_2 and vocabulary_id='LOINC' where relationship_id='Answer of') pc on concept_id_1=standard
  -- check against alllowed vocab-domain combos
  left join vocab_domain using(vocabulary_id, domain_id)
  where partner = '__partner_name__' -- restrict output to only the current data partner
)
select * from crit_sta;

-- filter out only concepts that have a problem
drop table if exists sta;
create temp table sta as
with sta as (
  select *
  from crit_sta where critique is not null
)
select * from sta;

-- critique source concepts and their mappings
drop table if exists crit_so;
create temp table crit_so as
with crit_so as(
  select partner, 'Source' as concept, source, concept_name, vocabulary_id,
    case 
      when source is null then 'Concept NULL'
      when source=0 then 'Concept 0'
      when source>2000000000 then '2-Billionaire'
      when concept_id is null then 'Concept unknown'
      when should.source is not null and (standard is null or standard=0) then 'Mapping available'
      when should.source is not null and ismap.source is null then 'Wrong mapping'
      when should.source is null and (standard is null or standard=0) then 'Needs mapping'
      else null
    end as critique,
    cnt
  from __schema__.general
  join d using(domain) 
  left join __cdm_schema__.concept on concept_id=source
  left join should using(source)
  left join ismap using(source, standard)
  where partner = '__partner_name__' -- restrict output to only the current data partner
)
select * from crit_so;

-- filter out only concepts that have a problem and sum up records for each concept
drop table if exists so;
create temp table so as
with so as (
  select partner, 'Source' as concept, source, concept_name, vocabulary_id, '' as domain_id, '' as is_domain, critique, sum(cnt) as records
  from crit_so where critique is not null
  group by partner, source, concept_name, vocabulary_id, domain_id, is_domain, critique
)
select * from so;

-- Individual report for all problematic concepts
-- used to be "Individual concept report.txt"
delete from __schema__.individual_concept_report
where partner = '__partner_name__';

insert into __schema__.individual_concept_report
select * from sta
where partner = '__partner_name__'
union
select * from so
where partner = '__partner_name__';

-- Summary for standard concepts
-- used to be "Standard summary report.txt"
delete from __schema__.standard_summary_report
where partner = '__partner_name__';

insert into __schema__.standard_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from __schema__.general group by partner
),
cst_summed as ( -- sum up records per critique
  select partner, critique, sum(records) as records
  from sta
  group by partner, critique
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%"
from cst_summed join cnts using(partner)
where partner = '__partner_name__'
order by 1, 2;

-- Summary for source concepts
-- used to be "Source summary report.txt"
delete from __schema__.source_summary_report
where partner = '__partner_name__';

insert into __schema__.source_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from __schema__.general group by partner
),
cst_summed as ( -- sum up records per critique, combine concept=NULL and concept=0
  select partner, critique, sum(records) as records
  from (
    select partner, case critique
      when 'Concept NULL' then 'Concept 0 or NULL'
      when 'Concept 0' then 'Concept 0 or NULL'
      else critique
    end as critique,
    records
    from so
    where critique in ('Concept NULL', 'Concept 0', '2-Billionaire', 'Concept unknown')
  )
  group by partner, critique
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%"
from cst_summed join cnts using(partner)
where partner = '__partner_name__'
order by 1, 2;

-- Summary mapping report
-- used to be "Mapping summary report.txt"
delete from __schema__.mapping_summary_report
where partner = '__partner_name__';

insert into __schema__.mapping_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from __schema__.general group by partner
),
cst_summed as ( -- sum up records per ciritque
  select partner, critique, sum(records) as records
  from so
  where critique in ('Wrong mapping', 'Needs mapping', 'Mapping available')
  group by partner, critique
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%"
from cst_summed join cnts using(partner)
where critique is not null
and partner = '__partner_name__'
order by 1, 2;

insert into __schema__.rolled_up_tumor_types
select *
from temp_tumor_types;

-- critique only standard concepts related to patch
drop table if exists crit_sta;
create temp table crit_sta as
with crit_sta as (
  select partner, 'Standard' as concept, concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable') then 'Flavor of NULL'
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_grade) then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_stage) then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_met) then 'Invalid met or node'
      when vocab_domain.vocabulary_id is null then 'Wrong vocab for domain'
      when loincvar is not null then 'Wrong LOINC postcoordination'
      when is_domain!=domain_id then 'Wrong domain table'
      when is_domain='Meas Value' then 'Meas Value overloaded'
      when standard_concept is null then 'Not standard concept'
      else null 
    end as critique, 
    records
  from (select partner, standard, is_domain, sum(cnt) as records from __schema__.general_cleaned join d using(domain) group by partner, standard, is_domain) as general
  join __cdm_schema__.concept on concept_id=standard
-- see if LOINC value, which needs to be pre-coordinated
  left join (select distinct concept_id_1, 1 as loincvar from __cdm_schema__.concept_relationship join __cdm_schema__.concept on concept_id=concept_id_2 and vocabulary_id='LOINC' where relationship_id='Answer of') pc on concept_id_1=standard
  -- check against alllowed vocab-domain combos
  left join vocab_domain using(vocabulary_id, domain_id)
  where partner = '__partner_name__' -- restrict output to only the current data partner
)
select * from crit_sta;

-- filter out only concepts that have a problem
drop table if exists sta;
create temp table sta as
with sta as (
  select *
  from crit_sta where critique is not null
)
select * from sta;

delete from __schema__.standard_summary_report_cleaned
where partner = '__partner_name__';

insert into __schema__.standard_summary_report_cleaned
with cnts as (
  select partner, sum(cnt) as t_records, count(distinct(standard)) as t_concepts
  from __schema__.general_cleaned
  where partner = '__partner_name__'
  group by partner
),
cst_summed as ( -- sum up records per critique
  select partner, critique, sum(records) as records, count(distinct(concept_id)) as concepts
  from sta
  group by partner, critique
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%",
concepts, round(concepts*1.0/t_concepts, 4) as "concept_%"
from cst_summed join cnts using(partner)
order by 1, 2;

delete from __schema__.histo_topo_percent
where partner = '__partner_name__';

insert into __schema__.histo_topo_percent
with oneleggeds as (
  select partner, sum(cnt) as onelegged
  from __schema__.general
  join static.onelegged_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
shallows as (
  select partner, sum(cnt) as shallow
  from __schema__.general
  join static.shallow_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
metastatics as (
  select partner, sum(cnt) as metastatic
  from __schema__.general
  join static.metastatic_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as (
  select partner, sum(cnt) as total
  from __schema__.general
  join static.all_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
)
select partner, coalesce(round(onelegged * 100.0 / total, 2), 0.00) as onelegged_cancer, 
coalesce(round(shallow * 100.0 / total, 2), 0.00) as shallow_cancer,
coalesce(round(metastatic * 100.0 / total, 2), 0.00) as metastatic_cancer
from __schema__.patient
left join totals using(partner)
left join oneleggeds using(partner)
left join shallows using(partner)
left join metastatics using(partner)
where partner = '__partner_name__';

delete from __schema__.met_grade_stage
where partner = '__partner_name__';

insert into __schema__.met_grade_stage
with mets as (
  select partner, sum(cnt) as met
  from __schema__.general
  join static.all_met on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
grades as (
  select partner, sum(cnt) as grade
  from __schema__.general
  join static.all_grade on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
stages as (
  select partner, sum(cnt) as stage
  from __schema__.general
  join static.all_stage on standard = concept_id
  where partner = '__partner_name__'
  group by partner
)
select partner, coalesce(met, 0) as met, coalesce(grade, 0) as grade, coalesce(stage, 0) as stage
from __schema__.patient
left join mets using (partner)
left join grades using (partner)
left join stages using (partner)
where partner = '__partner_name__';
