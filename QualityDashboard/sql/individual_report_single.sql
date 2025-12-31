/* uses placeholders
   __schema__ - the schema containing the results from the user
   __cdm_schema__ - the schema containing the vocabulary tables (concept, etc.)
   __partner_name__ - the name of the data partner to calculate results for
*/

drop table if exists general_no_extra;
create temp table general_no_extra as
with exclusions as (
  select concept_id
  from static.additional_conditions
  union
  select concept_id
  from static.lab_category
  union
  select concept_id
  from static.excluded_concepts -- These are concepts that appeared in the extract for inexplicable reasons.
)
select * from __schema__.general
where (standard is null
  or standard not in (
    select * from exclusions
  ))
and (source is null
  or source not in (
    select * from exclusions
  ));

-- update database_summary for this partner
-- used to be "Database summary.txt"
delete from __schema__.database_summary s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_patient;

insert into __schema__.database_summary
with non_canc as (
  select partner, count(*) as non_cancer
  from __schema__.general
  join static.additional_conditions on standard = concept_id
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner
),
patients as (
  select partner, cnt as size, version -- We use the patient version for the resulting table.
  from __schema__.patient
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_patient
),
generals as (
  select partner, count(*) as general
  from general_no_extra
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner
),
genomics as (
  select partner, count(*) as genomic
  from __schema__.genomic
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_genomic
  group by partner
),
episode as (
  select partner, count(*) as episodes
  from __schema__.episodes
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_episodes
  group by partner
),
lab_test as (
  select partner, count(*) as lab_tests
  from __schema__.measurement
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner
)
select partner, size, general, genomic, episodes, lab_tests, non_cancer, version
from patients
left join non_canc using(partner)
left join generals using(partner)
left join genomics using(partner)
left join episode using(partner)
left join lab_test using(partner)
order by partner;

delete from __schema__.general_cleaned
where partner = '__partner_name__';

insert into __schema__.general_cleaned
with replace_null as (
  -- This makes sure null in standard is joined as 0 (which is in white_list).
  select partner, domain, source, coalesce(standard, 0) as standard, cnt, version
  from general_no_extra
)
select g.*
from replace_null g
join patch.white_list on concept_id = standard
where partner = '__partner_name__';

-- Domain weight (# records per domain) report.
-- used to be "Domain weights.txt"
delete from __schema__.domain_weights w
using __schema__.cur_version v
where w.partner = v.partner
and w.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.domain_weights
with cnts as ( -- total number of records per partner
  select partner, sum(cnt) as t_records, version
  from general_no_extra 
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner, version
)
select partner, domain, records, round(records*1.0/t_records, 4) as "records_%", version
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
      when 's' then 'Spec Anatomic Site'
      else ''
    end as domain, 
    sum(cnt) as records, version
  from general_no_extra
  where partner = '__partner_name__'
  group by partner, domain, version
) a join cnts using(partner, version)
order by 1, 4 desc;


-- Rolled-up tumor types report
-- used to be "Rolled-up tumor types.txt"
delete from __schema__.rolled_up_tumor_types t
using __schema__.cur_version v
where t.partner = v.partner
and t.partner = '__partner_name__'
and version = cur_general;

drop table if exists general_last_version;

create temp table general_last_version as
select g.*
from general_no_extra g
join __schema__.cur_version using(partner)
where domain='c'
and partner = '__partner_name__'
and version = cur_general;

drop table if exists temp_tumor_descendants;

create temp table temp_tumor_descendants as
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
)
select descendant_concept_id as standard, t_name, p 
from __cdm_schema__.concept_ancestor 
join cancer_type on concept_id=ancestor_concept_id;

drop table if exists temp_tumor_types;

create temp table temp_tumor_types as
with c_types as (
  select distinct partner, standard, first_value(t_name) over (partition by standard order by p) as cancer_type, cnt, version
  from general_last_version
  join temp_tumor_descendants using(standard)
),
exist_types as ( -- to report on the same tumor types for each partner, even if it doesn't have each.
  select distinct cancer_type from c_types
),
cst_summed as ( -- sum up records and force into report all partners and tumor types 
  select partner, cancer_type, sum(cnt) as records, version
  from c_types
  group by partner, cancer_type, version
),
conditions as ( -- instead of total number of records per partner only those in the Condition table
  select partner, sum(cnt) as t_records, version
  from general_last_version 
  group by partner, version
)
select partner, cancer_type, records, round(records*1.0/t_records, 4) as "record_%", version
from cst_summed join conditions using(partner, version)
order by 1, 3 desc;

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
    ('v', 'Meas Value'),
    ('s', 'Spec Anatomic Site')
)
select * from d;

-- all source concepts and their correct mappings from concept_relationship
drop table if exists should;
create temp table should as 
with should as (
  select distinct source
  from general_no_extra
  join __cdm_schema__.concept_relationship on concept_id_1=source and invalid_reason is null and relationship_id in ('Maps to', 'Maps to value') and concept_id_1!=concept_id_2
)
select * from should;

-- source-standard pairs that also exist as "Maps to" relationships
drop table if exists ismap;
create temp table ismap as 
with ismap as (
  select distinct source, standard
  from general_no_extra
  join __cdm_schema__.concept_relationship on concept_id_1=source and concept_id_2=standard and invalid_reason is null and relationship_id='Maps to'
    and concept_id_1!=concept_id_2
)
select * from ismap;

drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from general_no_extra g
join __schema__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

drop table if exists domain_links;
create temp table domain_links as
with all_data as (
  select partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, sum(cnt) as records, version
  from general_last_version
  join d using(domain)
  join __cdm_schema__.concept on concept_id=standard
  group by partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, version
),
static_patched as ( -- all standard concepts that are a target_concept_id in patch.mapping
  select a.concept_id as standard, 1 as patched, target_domain_id as patched_domain
  from all_data a
  join patch.mapping on a.concept_id = target_concept_id
),
static_to_patch as ( -- concepts mentioned in patch.mapping as incorrect will get wrong_vocab 1
  select partner, concept_id as standard, concept_name, vocabulary_id, domain_id, is_domain, standard_concept,
  case when p.concept_id is not null then 1 else null end as wrong_vocab,
  records, version
  from all_data
  left join patch.mapping p using(concept_id)
),
valid_target as ( -- concepts belonging to a regular domain (that a table exists for)
  select standard, 1 as can_map
  from static_to_patch
  where wrong_vocab is null
  and domain_id in (
    select is_domain from d
  )
)
select distinct partner, standard, concept_name, vocabulary_id, coalesce(patched_domain, domain_id) as domain_id, 
is_domain, standard_concept, wrong_vocab, patched,
case when is_domain != coalesce(patched_domain, domain_id) and wrong_vocab is null and (is_domain <> 'Observation' or can_map is not null) then 1 else null end as wrong_domain,
records, version
from static_to_patch
left join valid_target using(standard)
left join static_patched using(standard)
;

-- critique standard concepts
drop table if exists crit_sta;
create temp table crit_sta as
with crit_sta as (
  select partner, 'Standard' as concept, standard as concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
	  when patched is not null and domain_id = is_domain then null -- A concept that is correct according to patch.mapping could still be in the wrong domain.
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable') then 'Flavor of NULL'
-- Concepts used as target_concept_id in patch.mapping won't be reported as non-standard or invalid.
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_grade) and patched is null then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_stage) and patched is null then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_met) and patched is null then 'Invalid met or node'
      when loincvar is not null then 'Wrong LOINC postcoordination'
      when standard_concept is null and patched is null then 'Not standard concept'
      when wrong_vocab is not null then 'Wrong vocab for domain' -- These are concepts used as concept_id in patch.mapping that weren't citicized for anything else.
      when wrong_domain is not null then 'Wrong domain table'
      when is_domain='Meas Value' then 'Meas Value overloaded'
      else null 
    end as critique, 
    records, version
  from domain_links
-- see if LOINC value, which needs to be pre-coordinated
  left join (select distinct concept_id_1, 1 as loincvar from __cdm_schema__.concept_relationship join __cdm_schema__.concept on concept_id=concept_id_2 and vocabulary_id='LOINC' where relationship_id='Answer of') pc on concept_id_1=standard
  -- check against alllowed vocab-domain combos
  --left join vocab_domain using(vocabulary_id, domain_id)
  --where partner = '__partner_name__' -- restrict output to only the current data partner
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

-- This table is for the partner-specific concept patch to fill the table new_concept.
delete from __schema__.patch_domain;
insert into __schema__.patch_domain
with inputs as (
  select distinct concept_id, domain_id as target_domain_id
  from sta
  where critique = 'Wrong domain table'
),
valid_target as (
  select concept_id, 1 as can_map
  from inputs
  where target_domain_id in (
    select is_domain from d
  )
  and target_domain_id <> 'Spec Anatomic Site' -- we don't move to the specimen table
)
select concept_id,
case when can_map is not null then target_domain_id else 'Observation' end as target_domain_id
from inputs
left join valid_target using(concept_id);

-- This table is for the partner-specific concept patch to fill the table mapping.
delete from __schema__.patch_mapping;
insert into __schema__.patch_mapping
with non_standard as (
  select concept_id, is_domain
  from sta
  where critique = 'Not standard concept'
),
sta_mapping as (
  select s.concept_id, concept_id_2 as target_concept_id, domain_id as target_domain_id, is_domain
  from non_standard s
  join __cdm_schema__.concept_relationship on s.concept_id = concept_id_1 and relationship_id = 'Maps to'
  join __cdm_schema__.concept c on concept_id_2 = c.concept_id
),
to_keep as (
  select concept_id, target_concept_id, 1 as keep_mapping
  from sta_mapping
  where target_domain_id in (
    select is_domain from d
  )
  and target_domain_id <> 'Spec Anatomic Site' -- we don't move to the specimen table
)
select concept_id, target_concept_id,
case 
when keep_mapping is not null then target_domain_id 
else 'Observation' 
end as target_domain_id
from sta_mapping
left join to_keep using (concept_id, target_concept_id)
order by 1;

-- This is for the partner-specific combi patch.
delete from __schema__.patch_combi;
insert into __schema__.patch_combi
with last_version as (
  select g.* 
  from __schema__.general g
  join __schema__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
)
select distinct cancer_id, histo_id, topo_id
from static.cancer_histo_topo
join last_version h on histo_id = h.standard
join last_version t on topo_id = t.standard
order by cancer_id, topo_id, histo_id;

-- critique source concepts and their mappings
drop table if exists crit_so;
create temp table crit_so as
with static_patched as (
  select distinct standard, 1 as patched
  from general_last_version
  join patch.mapping on standard = target_concept_id
),
crit_so as(
  select partner, 'Source' as concept, source, concept_name, vocabulary_id,
    case 
      when source is null then 'Concept NULL'
      when source=0 then 'Concept 0'
      when source>2000000000 then '2-Billionaire'
      when concept_id is null then 'Concept unknown'
	  when patched is not null then null -- Concepts used as target_concept_id in patch.mapping won't be reported as incorrectly mapped.
      when should.source is not null and (standard is null or standard=0) then 'Mapping available'
      when should.source is not null and ismap.source is null then 'Wrong mapping'
      when should.source is null and (standard is null or standard=0) then 'Needs mapping'
      else null
    end as critique,
    cnt, version
  from general_last_version
  join d using(domain) 
  left join __cdm_schema__.concept on concept_id=source
  left join should using(source)
  left join ismap using(source, standard)
  left join static_patched using(standard)
  where partner = '__partner_name__' -- restrict output to only the current data partner
)
select * from crit_so;

-- filter out only concepts that have a problem and sum up records for each concept
drop table if exists so;
create temp table so as
with so as (
  select partner, 'Source' as concept, source, concept_name, vocabulary_id, '' as domain_id, '' as is_domain, critique, sum(cnt) as records, version
  from crit_so where critique is not null
  group by partner, source, concept_name, vocabulary_id, domain_id, is_domain, critique, version
)
select * from so;

-- Individual report for all problematic concepts
-- used to be "Individual concept report.txt"
delete from __schema__.individual_concept_report i
using __schema__.cur_version v
where i.partner = v.partner
and i.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.individual_concept_report
with the_union as (
  select * from sta
  where partner = '__partner_name__'
  union
  select * from so
  where partner = '__partner_name__'
)
select * from the_union;

-- Summary for standard concepts
-- used to be "Standard summary report.txt"
delete from __schema__.standard_summary_report s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.standard_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from general_last_version group by partner
),
cst_summed as ( -- sum up records per critique
  select partner, critique, sum(records) as records, version
  from sta
  group by partner, critique, version
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%", version
from cst_summed join cnts using(partner)
where partner = '__partner_name__'
order by 1, 2;

-- Summary for source concepts
-- used to be "Source summary report.txt"
delete from __schema__.source_summary_report s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.source_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from general_last_version group by partner
),
cst_summed as ( -- sum up records per critique, combine concept=NULL and concept=0
  select partner, critique, sum(records) as records, version
  from (
    select partner, case critique
      when 'Concept NULL' then 'Concept 0 or NULL'
      when 'Concept 0' then 'Concept 0 or NULL'
      else critique
    end as critique,
    records, version
    from so
    where critique in ('Concept NULL', 'Concept 0', '2-Billionaire', 'Concept unknown')
  )
  group by partner, critique, version
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%", version
from cst_summed join cnts using(partner)
where partner = '__partner_name__'
order by 1, 2;

-- Summary mapping report
-- used to be "Mapping summary report.txt"
delete from __schema__.mapping_summary_report s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.mapping_summary_report
with cnts as (
  select partner, sum(cnt) as t_records from general_last_version group by partner
),
cst_summed as ( -- sum up records per ciritque
  select partner, critique, sum(records) as records, version
  from so
  where critique in ('Wrong mapping', 'Needs mapping', 'Mapping available')
  group by partner, critique, version
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%", version
from cst_summed join cnts using(partner)
where critique is not null
and partner = '__partner_name__'
order by 1, 2;

insert into __schema__.rolled_up_tumor_types
select *
from temp_tumor_types;

-- critique only standard concepts related to patch
drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from __schema__.general_cleaned g
join __schema__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

drop table if exists domain_links;
create temp table domain_links as
with all_data as (
  select partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, sum(cnt) as records, version
  from general_last_version
  join d using(domain)
  join __cdm_schema__.concept on concept_id=standard
  group by partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, version
),
static_patched as ( -- all standard concepts that are a target_concept_id in patch.mapping
  select a.concept_id as standard, 1 as patched, target_domain_id as patched_domain
  from all_data a
  join patch.mapping on a.concept_id = target_concept_id
),
static_to_patch as ( -- concepts mentioned in patch.mapping as incorrect will get wrong_vocab 1
  select partner, concept_id as standard, concept_name, vocabulary_id, domain_id, is_domain, standard_concept,
  case when p.concept_id is not null then 1 else null end as wrong_vocab,
  records, version
  from all_data
  left join patch.mapping p using(concept_id)
),
valid_target as ( -- concepts belonging to a regular domain (that a table exists for)
  select standard, 1 as can_map
  from static_to_patch
  where wrong_vocab is null
  and domain_id in (
    select is_domain from d
  )
)
select distinct partner, standard, concept_name, vocabulary_id, coalesce(patched_domain, domain_id) as domain_id, 
is_domain, standard_concept, wrong_vocab, patched,
case when is_domain != coalesce(patched_domain, domain_id) and wrong_vocab is null and (is_domain <> 'Observation' or can_map is not null) then 1 else null end as wrong_domain,
records, version
from static_to_patch
left join valid_target using(standard)
left join static_patched using(standard)
;

-- critique standard concepts
drop table if exists crit_sta;
create temp table crit_sta as
with crit_sta as (
  select partner, 'Standard' as concept, standard as concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
	  when patched is not null and domain_id = is_domain then null -- A concept that is correct according to patch.mapping could still be in the wrong domain.
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable') then 'Flavor of NULL'
-- Concepts used as target_concept_id in patch.mapping won't be reported as non-standard or invalid.
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_grade) and patched is null then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_stage) and patched is null then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from static.invalid_met) and patched is null then 'Invalid met or node'
      when loincvar is not null then 'Wrong LOINC postcoordination'
      when standard_concept is null and patched is null then 'Not standard concept'
      when wrong_vocab is not null then 'Wrong vocab for domain' -- These are concepts used as concept_id in patch.mapping that weren't citicized for anything else.
      when wrong_domain is not null then 'Wrong domain table'
      when is_domain='Meas Value' then 'Meas Value overloaded'
      else null 
    end as critique, 
    records, version
  from domain_links
-- see if LOINC value, which needs to be pre-coordinated
  left join (select distinct concept_id_1, 1 as loincvar from __cdm_schema__.concept_relationship join __cdm_schema__.concept on concept_id=concept_id_2 and vocabulary_id='LOINC' where relationship_id='Answer of') pc on concept_id_1=standard
  -- check against alllowed vocab-domain combos
  --left join vocab_domain using(vocabulary_id, domain_id)
  --where partner = '__partner_name__' -- restrict output to only the current data partner
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

delete from __schema__.standard_summary_report_cleaned s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.standard_summary_report_cleaned
with cnts as (
  select partner, sum(cnt) as t_records, count(distinct(standard)) as t_concepts
  from general_last_version
  where partner = '__partner_name__'
  group by partner
),
cst_summed as ( -- sum up records per critique
  select partner, critique, sum(records) as records, count(distinct(concept_id)) as concepts, version
  from sta
  group by partner, critique, version
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%",
concepts, round(concepts*1.0/t_concepts, 4) as "concept_%", version
from cst_summed join cnts using(partner)
order by 1, 2;

drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from general_no_extra g
join __schema__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

delete from __schema__.histo_topo_percent h
using __schema__.cur_version v
where h.partner = v.partner
and h.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.histo_topo_percent
with oneleggeds as (
  select partner, sum(cnt) as onelegged
  from general_last_version
  join static.onelegged_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
shallows as (
  select partner, sum(cnt) as shallow
  from general_last_version
  join static.shallow_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as (
  select partner, sum(cnt) as total
  from general_last_version
  join static.all_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
both_sides as (
  select partner, total - coalesce(onelegged, 0) - coalesce(shallow, 0) as both_r
  from totals
  left join oneleggeds using(partner)
  left join shallows using(partner)
)
select partner, coalesce(onelegged, 0) as onelegged_records,
coalesce(round(onelegged * 100.0 / total, 2), 0.00) as onelegged_perc, 
coalesce(shallow, 0) as shallow_records,
coalesce(round(shallow * 100.0 / total, 2), 0.00) as shallow_perc,
coalesce(both_r, 0) as both_records,
coalesce(round(both_r * 100.0 / total, 2), 0.00) as both_perc, version
from __schema__.patient
join __schema__.cur_version using(partner)
left join totals using(partner)
left join oneleggeds using(partner)
left join shallows using(partner)
left join both_sides using(partner)
where partner = '__partner_name__'
and version = cur_general;

delete from __schema__.histo_topo_individual h
using __schema__.cur_version v
where h.partner = v.partner
and h.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.histo_topo_individual
with concepts as (
  select partner, standard as concept_id, 'One-legged cancer' as critique, sum(cnt) as records, version
  from general_last_version
  join static.onelegged_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner, standard, version
  union
  select partner, standard, 'Shallow cancer' as critique, sum(cnt), version
  from general_last_version
  join static.shallow_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner, standard, version
)
select partner, concept_id, concept_name, critique, records, version
from concepts
join __cdm_schema__.concept using (concept_id)
order by partner, critique, concept_id;

-- Stages

delete from __schema__.stages s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into __schema__.stages
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_last_version
  join static.invalid_stage on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_last_version
  join static.all_stage on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as ( -- all records of the partner, regardless of category
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as total
  from general_last_version
  where partner = '__partner_name__'
  group by partner
)
select partner, coalesce(bad, 0) as bad_cnt, -- bad records of the category
coalesce(whole_cat, 0) as all_cnt, -- all records of the category, regardless of correctness
coalesce(round(bad * 100.0 / whole_cat, 2), 0.00) as bad_from_all, -- percentage of bad records in all_cnt
coalesce(round(whole_cat * 100.0 / total, 2), 0.00) as all_from_total, -- percentage of all_cnt from all db records
coalesce(round(bad * 100.0 / total, 2), 0.00) as bad_from_total, -- percentage of bad records from all db records,
version
from __schema__.patient
join __schema__.cur_version using(partner)
left join bads using (partner)
left join wholes using (partner)
left join totals using (partner)
where partner = '__partner_name__'
and version = cur_general
;

-- Grades

delete from __schema__.grades g
using __schema__.cur_version v
where g.partner = v.partner
and g.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into __schema__.grades
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_last_version
  join static.invalid_grade on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_last_version
  join static.all_grade on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as ( -- all records of the partner, regardless of category
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as total
  from general_last_version
  where partner = '__partner_name__'
  group by partner
)
select partner, coalesce(bad, 0) as bad_cnt, -- bad records of the category
coalesce(whole_cat, 0) as all_cnt, -- all records of the category, regardless of correctness
coalesce(round(bad * 100.0 / whole_cat, 2), 0.00) as bad_from_all, -- percentage of bad records in all_cnt
coalesce(round(whole_cat * 100.0 / total, 2), 0.00) as all_from_total, -- percentage of all_cnt from all db records
coalesce(round(bad * 100.0 / total, 2), 0.00) as bad_from_total, -- percentage of bad records from all db records
version
from __schema__.patient
join __schema__.cur_version using(partner)
left join bads using (partner)
left join wholes using (partner)
left join totals using (partner)
where partner = '__partner_name__'
and version = cur_general
;

-- Metastases

delete from __schema__.mets m
using __schema__.cur_version v
where m.partner = v.partner
and m.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into __schema__.mets
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_no_extra
  join static.invalid_met on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_no_extra
  join static.all_met on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as ( -- all records of the partner, regardless of category
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as total
  from general_no_extra
  where partner = '__partner_name__'
  group by partner
)
select partner, coalesce(bad, 0) as bad_cnt, -- bad records of the category
coalesce(whole_cat, 0) as all_cnt, -- all records of the category, regardless of correctness
coalesce(round(bad * 100.0 / whole_cat, 2), 0.00) as bad_from_all, -- percentage of bad records in all_cnt
coalesce(round(whole_cat * 100.0 / total, 2), 0.00) as all_from_total, -- percentage of all_cnt from all db records
coalesce(round(bad * 100.0 / total, 2), 0.00) as bad_from_total, -- percentage of bad records from all db records
version
from __schema__.patient
join __schema__.cur_version using(partner)
left join bads using (partner)
left join wholes using (partner)
left join totals using (partner)
where partner = '__partner_name__'
and version = cur_general
;

-- intermediate tables for long and summary lab report

drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from __schema__.general g
join __schema__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

-- create denominators for concepts and values
drop table if exists general_counts;
create temp table general_counts as
select partner, category as cat, sum(cnt) as denom
from static.lab_category
join general_last_version on standard=concept_id
where partner = '__partner_name__'
group by partner, cat;

drop table if exists measurement_last_version;
create temp table measurement_last_version as
select m.*
from __schema__.measurement m
join __schema__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_patient;

-- detailed report on wrong value as concept
drop table if exists concept_long_report;
create temp table concept_long_report as
-- categorized value concepts if not null or not 0
with concept_cat as (
  select partner, category as cat, prec, m.concept_id as m_id, m.concept_name as m_name, value_as_concept_id as v_id, v.concept_name as v_name, v.concept_class_id, v.domain_id,
    sum(coalesce(cnt, 1)) as records, version
  from measurement_last_version r
  join static.lab_category c on c.concept_id=r.measurement_concept_id
  join __cdm_schema__.concept m on m.concept_id=r.measurement_concept_id
  join __cdm_schema__.concept v on v.concept_id=r.value_as_concept_id
  where value_as_concept_id is not null and value_as_concept_id!=0
  and partner = '__partner_name__'
  group by partner, category, prec, m.concept_id, m.concept_name, value_as_concept_id, v.concept_name, 
  v.concept_class_id, v.domain_id, version
),
concept_tot as (
  select partner, sum(records) as total
  from concept_cat
  group by partner
)
select partner, cat, m_id, m_name, v_id, v_name, case
  when concept_class_id='Lab Test' then 'Measurement concept'
  when prec is not null then 'Precoordinated'
  when pg_input_is_valid(replace(replace(replace(v_name, '%', ''), '>', ''), '<', ''), 'numeric') then 'Number' 
  when domain_id='Meas Value' and (v_name like '%or greater%' or v_name like '%or less%') then 'Number'
  when v_name='Above reference range' then 'Good' -- valid value_as_concept
  when v_name='Below reference range' then 'Good' -- valid value_as_conceptv
  when v_name='Normal' then 'Good' -- valid value_as_concept
  when v_name='Not elevated	' then 'Good' -- valid value_as_concept
  when v_name='NA' then 'Flavor of Null'
  when v_name='DNR' then 'Flavor of Null'
  when v_name='N/A' then 'Flavor of Null'
  when v_name='Not applicable' then 'Flavor of Null'
  when v_name='Not Applicable' then 'Flavor of Null'
  when v_name='Not given' then 'Flavor of Null'	
  when v_name='Not measured' then 'Flavor of Null'	
  when v_name='Not performed/received' then 'Flavor of Null'	
  when v_name='Not reportable' then 'Flavor of Null'	
  when v_name='Not action taken' then 'Flavor of Null'
  when v_name='No result' then 'Flavor of Null'
  when v_name='No sample received' then 'Flavor of Null'
  when v_name='Null' then 'Flavor of Null'
  when v_name='Quantity insufficient' then 'Flavor of Null'
  when v_name='Not done' then 'Flavor of Null'
  when v_name='Test not done' then 'Flavor of Null'
  when v_name='Not performed' then 'Flavor of Null'
  when v_name='Pending' then 'Flavor of Null'
  when v_name='Service comment' then 'Flavor of Null'
  when v_name='Unable to complete' then 'Flavor of Null'	
  when v_name='Unable to do' then 'Flavor of Null'	
  when v_name='Unavailable' then 'Flavor of Null'	
  when v_name='Unknown/No answer' then 'Flavor of Null'	
  when v_name like '%Grade %' then 'Good'
  when v_name like 'KPS %' then 'Good' -- Karnofsky
  when v_name like 'Karnofsky Performance Scale (KPS)%' then 'Good'
  when v_name like 'Class %' then 'Good' -- NYHA class
  when v_name like 'ECOG performance status%' then 'Good'
  else 'Not valid value'
  end as critique, records, 100.0*records/total as pct_con_rcs, version
from concept_cat
join general_counts using(partner, cat)
join concept_tot using(partner);

-- detailed report on wrong value distributions
drop table if exists value_long_report;
create temp table value_long_report as
-- categorized values
with value_cat as (
  select partner, cat, m_id, m_name, u_id, u_name, range_low, range_high, p_03, p_25, median, p_75, p_97, sum(cnt) as records, version from (
    select partner, category as cat, m.concept_id as m_id, m.concept_name as m_name, u.concept_id as u_id, u.concept_name as u_name, 
      range_low, range_high, 
      case p_03 when 0 then null else p_03 end as p_03,
      case p_25 when 0 then null else p_25 end as p_25,
      case median when 0 then null else median end as median,
      case p_75 when 0 then null else p_75 end as p_75,
      case p_97 when 0 then null else p_97 end as p_97,
      coalesce(cnt, 1) as cnt, version
    from measurement_last_version r
    join static.lab_category c on c.concept_id=r.measurement_concept_id
    join __cdm_schema__.concept m on m.concept_id=r.measurement_concept_id
    left join __cdm_schema__.concept u on u.concept_id=r.unit_concept_id
    where partner = '__partner_name__'
  )
  where u_id!=0 or range_high!=0 or coalesce(u_id, range_low, range_high, p_03, p_25, median, p_75, p_97) is not null
  group by partner, cat, m_id, m_name, u_id, u_name, range_low, range_high, p_03, p_25, median, p_75, p_97, version
),
value_tot as (
  select partner, sum(records) as total
  from value_cat
  group by partner
),
normals (cat, unit, range_low, range_high, matching) as (values
  ('Hemoglobin', 'gram per deciliter', 12.0, 17.5, 'both'),
  ('Hemoglobin', 'gram per liter', 120.0, 170.5, 'both'),
  ('Hemoglobin', 'millimole per liter', 7.4, 10.8, 'both'),
  ('Platelets', 'thousand per microliter', 150, 450, 'both'),
  ('Platelets', 'million per microliter', 0.15, 0.45, 'both'),
  ('Platelets', 'ten thousand per microliter', 15, 45, 'both'),
  ('Platelets', 'thousand per liter', 150000, 450000, 'both'),
  ('ANC', 'thousand per microliter', 1.5, 8.0, 'both'),
  ('HbA1c', 'percent', 4, 5.7, 'upper'),
  ('HbA1c', 'millimole per mole', 25, 39, 'upper'),
  ('CrCl', 'mL/min', 88, 137, 'both'),
  ('Creatinine', 'milligram per deciliter', 0.6, 1.3, 'both'),
  ('Creatinine', 'milligram per liter', 6, 13, 'both'),
  ('Creatinine', 'milligram per milliliter', 0.006, 0.013, 'both'),
  ('Creatinine', 'microgram per deciliter', 600, 1300, 'both'),
  ('Creatinine', 'microgram per liter', 6000, 13000, 'both'),
  ('Creatinine', 'gram per deciliter', 0.0006, 0.0013, 'both'),
  ('Creatinine', 'micromole per liter', 53, 115, 'both'),
  ('Creatinine', 'millimmole per liter', 0.053, 0.115, 'both'),
  ('GFR', 'milliliter per minute per 1.73 square meter', 90, 90, 'lower'),
  ('GFR', 'liter per minute per square meter', 0.052, 0.052, 'lower'),
  ('PTT', 'second', 25, 35, 'both'),
  ('aPTT', 'second', 25, 35, 'both'),
  ('INR', 'ratio', 0.8, 1.2, 'both'),
  ('Direct bilirubin', 'milligram per deciliter', 0, 0.3, 'both'),
  ('Direct bilirubin', 'micromole/liter', 0, 5, 'both'),
  ('Total bilirubin', 'milligram per deciliter', 0.3, 1.2, 'both'),
  ('Total bilirubin', 'micromole/liter', 5, 21, 'both'),
  ('AST', 'unit per liter', 10, 40, 'both'),
  ('ALT', 'unit per liter', 7, 56, 'both'),
  ('Karnofsky', '', 0, 100, 'both'),
  ('ECOG', '', 0, 5, 'both'),
  ('NYHA', '', 1, 4, 'both')
),
p (a_name, u_name) as (values
  ('percent hemoglobin A1c', 'percent'),
  ('billion per liter', 'thousand per microliter'),
  ('thousand per cubic millimeter', 'thousand per microliter'),
  ('nanomole per milliliter', 'micromol per liter'),
  ('microgram per milliliter', 'milligram per liter'),
  ('international unit per liter', 'unit per liter')
)
select * from (
  select partner, v.cat, m_id, m_name, u_id, u_name, v.range_low, v.range_high, -- , n.unit as u, n.range_low, n.range_high,
    p_03, p_25, median, p_75, p_97,
    case when n.cat is null then 'Unusable' else null end as range,
    case when p_97 is null or p_97=0 then 'Missing' else null end as values, 
    case when p_03=p_97 then 'Small' else null end as spread,
  -- If unit or list of alternative units doesn't existing
    case when n.cat is not null and coalesce(v.u_name, '')!=unit and coalesce(v.u_name, '') not in (select a_name from p where p.u_name=unit) then 'Bad' else null end as unit,
  -- Outliers measured as the spread > 1000x or if there are 9999 in the values
    case when cast(p_97 as text) like '9999%' or p_25>0 and 
      p_97/coalesce(case v.range_high when 0 then null else v.range_high end, p_25)>1000.0 then 'Present' else null end as outliers,
    records, 100.0*records/total as pct_val_rcs, version
  from value_cat v
  join value_tot using(partner)
  -- this is where the existing ranges or percentiles are matched to the expected ones 
  left join normals n on v.cat=n.cat and (
    matching='both' and coalesce((v.range_low+v.range_high), p_25*2.0)/(n.range_low+n.range_high) between 0.62 and 1.62 or 
    matching='upper' and coalesce(v.range_high, median)/n.range_high between 0.62 and 1.62 or
    matching='lower' and coalesce(v.range_low, median)/n.range_low between 0.62 and 1.62
  )
)
where coalesce(range, values, spread, unit, outliers) is not null;

-- long lab report
delete from __schema__.lab_long_report l
using __schema__.cur_version v
where l.partner = v.partner
and l.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.lab_long_report (partner, cat, measurement_id, measurement_name, records, percent,
  p_03, p_25, median, p_75, p_97, value_id, value_name, concept_critique, pct_of_concept_recs,
  unit_id, unit_name, range_low, range_high, range, values, spread, unit, outliers, pct_of_value_recs, version)
with long_report as (
  -- report on value distribution
  select partner, cat, m_id as measurement_id, m_name as measurement_name, records, 100.0*records/denom as percent, 
  -- the original percentiles
  p_03, p_25, median, p_75, p_97,
  -- critique on value_as_concept_id
  null as value_id, null as value_name, null as concept_critique, null as pct_of_concept_recs,
  -- critique on distribution of values
  u_id as unit_id, u_name as unit_name, range_low, range_high, range, values, spread, unit, outliers, pct_val_rcs as pct_of_value_recs, version
  from value_long_report
  join general_counts using(partner, cat)
  union
  -- add report from value as concepts
  select partner, cat, m_id, m_name, records, 100.0*records/denom as percent, 
  null, null, null, null, null,
  v_id, v_name, critique, pct_con_rcs, 
  null, null, null, null, null, null, null, null, null, null, version
  from concept_long_report
  join general_counts using(partner, cat)
  where critique!='Good' and critique is not null
)
select * from long_report
order by partner, cat, measurement_name, value_name, unit_name, range_low, range_high;

-- summary lab report
delete from __schema__.lab_summary s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.lab_summary
with all_cat as (
  select distinct '__partner_name__' as partner, category as cat
  from static.lab_category
),
concept_summary as (
  select partner, cat, 
    sum(case critique when 'Number' then records else 0 end) as number,
    sum(case critique when 'Flavor of Null' then records else 0 end) as flavor_null,
    sum(case critique when 'Precoordinated' then records else 0 end) as precoordinated,
    sum(case critique when 'Measurement concept' then records else 0 end) as measurement,
    sum(case critique when 'Not valid value' then records else 0 end) as not_value,
    sum(case critique when 'Good' then records else 0 end) as good,
    sum(records) as concept_records, version as c_version
  from concept_long_report
  where partner = '__partner_name__'
  group by partner, cat, version
),      
value_summary as (
  select partner, cat,
    sum(case when unit is null then 0 else records end) as bad_unit,
    sum(case when range is null then 0 else records end) as bad_range,
    sum(case when values is null then 0 else records end) as missing_values,
    sum(case when spread is null then 0 else records end) as no_spread,
    sum(case when outliers is null then 0 else records end) as outliers,
    sum(case when coalesce(values, range) is null then 0 else records end) as hopeless,
    sum(records) as value_records, version as v_version
  from value_long_report
  where partner = '__partner_name__'
  group by partner, cat, version
)
select partner, cat, concept_records,
  case number when 0 then null else number end as number,
  case flavor_null when 0 then null else flavor_null end as flavor_null,
  case precoordinated when 0 then null else precoordinated end as precoordinated,
  case measurement when 0 then null else measurement end as measurement,
  case not_value when 0 then null else not_value end as not_value,
  100.0*case good when 0 then null else good end/concept_records as pct_usable_consets,  
  value_records,
  case bad_unit when 0 then null else bad_unit end as bad_unit,
  case bad_range when 0 then null else bad_range end as bad_range,
  case missing_values when 0 then null else missing_values end as missing_values,
  case no_spread when 0 then null else no_spread end as no_spread,
  case outliers when 0 then null else outliers end as outliers,
  100.0*(value_records-coalesce(hopeless, 0))/value_records as pct_usable_valsets,
  coalesce(v_version, c_version, 0) as version
from all_cat
left join concept_summary using(partner, cat)
left join value_summary using(partner, cat)
order by partner, cat;


delete from __schema__.special_conditions s
using __schema__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into __schema__.special_conditions
with ecogs as (
  select partner, 'ECOG' as critique, sum(cnt) as records, version
  from measurement_last_version
  join static.lab_category on concept_id = measurement_concept_id
  where partner = '__partner_name__'
  and category = 'ECOG'
  group by partner, version
),
karnofskys as (
  select partner, 'Karnofsky' as critique, sum(cnt) as records, version
  from measurement_last_version
  join static.lab_category on concept_id = measurement_concept_id
  where partner = '__partner_name__'
  and category = 'Karnofsky'
  group by partner, version
),
pd_l1s as (
  select partner, 'PD-L1' as critique, sum(cnt) as records, version
  from measurement_last_version
  join static.lab_category on concept_id = measurement_concept_id
  where partner = '__partner_name__'
  and category = 'PD-L1'
  group by partner, version
),
totals as (
  select partner, sum(cnt) as total
  from measurement_last_version
  where partner = '__partner_name__'
  group by partner
)
select partner, critique, coalesce(records, 0) as records, 
coalesce(round(records * 100.0 / total, 2), 0.00) as record_perc,
coalesce(version, 0) as version
from ecogs
join totals using(partner)
where records > 0
union
select partner, critique, coalesce(records, 0) as records, 
coalesce(round(records * 100.0 / total, 2), 0.00) as record_perc,
coalesce(version, 0)
from karnofskys
join totals using(partner)
where records > 0
union
select partner, critique, coalesce(records, 0) as records, 
coalesce(round(records * 100.0 / total, 2), 0.00) as record_perc,
coalesce(version, 0)
from pd_l1s
join totals using(partner)
where records > 0
;
