/* 
   This script contains the business logic for reporting errors and inconsistencies
   in the partner's data. The same script is used for calculating the latest data version
   (automatic) and earlier data versions (on demand).
   
   uses placeholders
   @__results__ - the schema containing the results from the user
   @__vocab__ - the schema containing the vocabulary tables (concept, etc.)
   __partner_name__ - the name of the data partner to calculate results for
*/

drop table if exists general_no_extra;
create temp table general_no_extra as
with exclusions as (
  select concept_id
  from @__static__.additional_conditions
  union
  select concept_id
  from @__static__.lab_category
  union
  select concept_id
  from @__static__.excluded_concepts -- These are concepts that appeared in the extract for inexplicable reasons.
)
select g.* 
from @__results__.general g
left join exclusions e1
on standard = e1.concept_id
left join exclusions e2
on source = e2.concept_id
where e1.concept_id is null
and e2.concept_id is null;


-- update database_summary for this partner
-- used to be "Database summary.txt"
delete from @__results__.database_summary s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_patient;

insert into @__results__.database_summary
with non_canc as (
  select partner, count(*) as non_cancer
  from @__results__.general
  join @__static__.additional_conditions on standard = concept_id
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner
),
patients as (
  select partner, cnt as size, version -- We use the patient version for the resulting table.
  from @__results__.patient
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_patient
),
generals as (
  select partner, count(*) as general
  from general_no_extra
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
  group by partner
),
genomics as (
  select partner, count(*) as genomic
  from @__results__.genomic
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_genomic
  group by partner
),
episode as (
  select partner, count(*) as episodes
  from @__results__.episodes
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_episodes
  group by partner
),
lab_test as (
  select partner, count(*) as lab_tests
  from @__results__.measurement
  join @__results__.cur_version using(partner)
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

delete from @__results__.general_cleaned
where partner = '__partner_name__';

insert into @__results__.general_cleaned
with replace_null as (
  -- This makes sure null in standard is joined as 0 (which is in white_list).
  select partner, domain, source, coalesce(standard, 0) as standard, cnt, version
  from general_no_extra
)
select *
from replace_null
where partner = '__partner_name__';

-- Domain weight (# records per domain) report.
-- used to be "Domain weights.txt"
delete from @__results__.domain_weights w
using @__results__.cur_version v
where w.partner = v.partner
and w.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.domain_weights
with cnts as ( -- total number of records per partner
  select partner, sum(cnt) as t_records, version
  from general_no_extra 
  join @__results__.cur_version using(partner)
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
delete from @__results__.rolled_up_tumor_types t
using @__results__.cur_version v
where t.partner = v.partner
and t.partner = '__partner_name__'
and version = cur_general;

drop table if exists general_last_version;

create temp table general_last_version as
select g.*
from general_no_extra g
join @__results__.cur_version using(partner)
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
from @__vocab__.concept_ancestor 
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
  join @__vocab__.concept_relationship on concept_id_1=source and invalid_reason is null and relationship_id in ('Maps to', 'Maps to value') and concept_id_1!=concept_id_2
)
select * from should;

-- concepts used in the source column that are standard concepts
drop table if exists standard_sources;
create temp table standard_sources as
select distinct source, 1 as source_is_standard
from general_no_extra
join @__vocab__.concept on source = concept_id
where standard_concept = 'S'
and invalid_reason is null;

-- source-standard pairs that also exist as "Maps to" relationships
drop table if exists ismap;
create temp table ismap as 
with ismap as (
  select distinct source, standard
  from general_no_extra
  join @__vocab__.concept_relationship on concept_id_1=source and concept_id_2=standard and invalid_reason is null and relationship_id='Maps to'
    and concept_id_1!=concept_id_2
)
select * from ismap;

drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from general_no_extra g
join @__results__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

drop table if exists domain_links;
create temp table domain_links as
with all_data as (
  select partner, concept_id as standard, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, sum(cnt) as records, version
  from general_last_version
  join d using(domain)
  join @__vocab__.concept on concept_id=standard
  group by partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, version
),
valid_target as ( -- concepts belonging to a regular domain (that a table exists for)
  select standard, 1 as can_map
  from all_data
  where domain_id in (
    select is_domain from d
	where is_domain <> 'Spec Anatomic Site'
  )
)
select distinct partner, standard, concept_name, vocabulary_id, domain_id, 
is_domain, standard_concept,
case when is_domain = 'Spec Anatomic Site' or is_domain != domain_id and (is_domain <> 'Observation' or can_map is not null) then 1 else null end as wrong_domain,
records, version
from all_data
left join valid_target using(standard)
;

-- critique standard concepts
drop table if exists crit_sta;
create temp table crit_sta as
with overloaded_concepts as (
  select concept_id_2 
  from @__vocab__.concept_relationship 
  where relationship_id='Has Answer'
  and invalid_reason is null 
  and concept_id_1 in (3020133, 3010621, 3020306, 40769814, 3043806, 40758258, 36203250, 40769831, 21494849, 3042720, 42527705, 3015048, 46236987, 46236986, 46235142, 3001410, 1091494, 3028485, 36304519, 3045092, 42527788, 3046070, 3047311, 3043846, 3043017, 40769849, 42527700, 3045426, 3019341, 3021037, 3002943, 40770067, 3017327, 3006171, 3032860, 3032820, 3032529, 3046523, 44816728, 36203176, 1617409, 1616763, 3002377, 36203154, 36203137, 1617315, 3043693, 36203118, 36203117, 36203124, 21494733, 3014845, 21492981, 1616553, 36305168, 3046972, 3044365, 3046527, 3045602, 21494735, 1616306, 3044724, 3042773, 3047277, 42527790, 40769833, 21491882, 21491880, 21491879, 21491881, 36204404, 21493968, 21493970, 21493971, 36031181, 42529177, 36031552, 21493969, 42527723, 42527720, 36203139, 21494724, 40762606, 3046434, 3008250, 3006038, 3007073, 3016292, 3046598, 36203181, 3047346, 3046361, 37020347, 42527712, 42527711, 36203169, 1617504, 1616523, 21493980, 21493979, 21493974, 21493976, 21493977, 21493975, 21493981, 40765594, 21493978, 21491883, 21490957, 3000766, 21494730)
),
value_needs_mapping as (
  select concept_id_2 
  from @__vocab__.concept_relationship 
  where relationship_id='Has Answer'
  and invalid_reason is null 
  and concept_id_1 in (3040950, 36031424, 44786879, 36204549, 44786934, 46235351, 3050686, 40760326, 40770159, 40770163, 3015763, 3026214, 3023877, 40766660, 1617452, 1616716, 40769855, 3019275, 3022835, 3000608, 3019130, 40766623, 40766625, 3003037, 21494723, 36204558, 1001824, 36305514, 36306187, 21491888, 21491887, 3051348, 40766653, 42527886, 40769122, 3012604, 36203179, 40769857, 40769820, 3001285, 36203138, 36305408, 36305927, 21491872, 3046315, 40771030, 40770927, 40770932, 42529083, 44786707, 44786708, 1989065, 42870406, 3004250, 21491611, 40769265, 3009329, 3038982, 3033619, 3034828, 3014280, 3027596, 3021444, 21494722, 3016725, 46235213, 3051551, 44816596, 3008181, 36203126, 1617595, 3043591, 36660206, 3006575, 40769842, 40769838, 21493972, 40762591, 3007727, 42528924, 3022698, 3018082, 3008495, 3016308, 3008841, 3027109, 40769836, 40769840, 3020821, 3021034, 42527715)
),
crit_sta as (
  select partner, 'Standard' as concept, standard as concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable', 'Not detected', 'N/A', 'Refused', 'No', 'Not specified', 'No tumor', 'Invalid', 'Other cancer-directed therapy recommended, unknown if administered', 'Don''t know', 'None', 'Not asked', 'No information', 'Unable to determine', 'Don''t know/refused', 'Patient refused', 'Not tested', 'Resident refused', 'Asked but unknown', 'Refused to answer') then 'Flavor of NULL'
      when standard in (select concept_id from @__static__.split_conditions) then 'Condition needs splitting'
      when coalesce(standard_concept, 'C')='C' then 'Not standard concept'
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_grade) then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_stage) then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_met) then 'Invalid met or node'
      when is_domain='Meas Value' and standard in (select concept_id_2 from value_needs_mapping) then 'Value needs mapping'
      when wrong_domain is not null then 'Wrong domain table'
      when is_domain='Meas Value' and standard in (select concept_id_2 from overloaded_concepts) then 'Value needs pre-coord mapping'
      else null 
    end as critique, 
    records, version
  from domain_links
-- see if LOINC value, which needs to be pre-coordinated
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

analyze sta;

-- Invalid concepts will be added to the shit_list.
insert into @__results__.shit_list(concept_id)
with critiques as
(
  select distinct concept_id
  from sta
  join @__results__.max_versions using(partner)
  where critique in ('Invalid grade', 'Invalid stage', 'Invalid met or node', 'Value needs pre-coord mapping', 'Value needs mapping')
  and version = max_general -- Making sure we don't add this when recalculating old delivery versions.
)
select * from critiques
except
select concept_id from @__results__.shit_list;

-- This table is for the partner-specific concept patch to fill the table new_concept.
delete from @__results__.patch_domain;
insert into @__results__.patch_domain
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
delete from @__results__.patch_mapping;
insert into @__results__.patch_mapping
with non_standard as (
  select distinct concept_id
  from sta
  join @__vocab__.concept using(concept_id)
  where coalesce(standard_concept, 'C')='C'
),
sta_mapping as (
  select s.concept_id, concept_id_2 as target_concept_id, domain_id as target_domain_id
  from non_standard s
  join @__vocab__.concept_relationship on s.concept_id = concept_id_1 
  and relationship_id = 'Maps to' and concept_id_1 <> concept_id_2
  join @__vocab__.concept c on concept_id_2 = c.concept_id
  where standard_concept is not null
),
shitty as (
  select concept_id, target_concept_id
  from sta
  join @__results__.shit_list using(concept_id)
  where critique in ('Invalid grade', 'Invalid stage', 'Invalid met or node', 'Value needs pre-coord mapping', 'Value needs mapping')
  and target_concept_id is not null
),
shit_mapping as (
  select s.concept_id, target_concept_id, domain_id as target_domain_id
  from shitty s
  join @__vocab__.concept c on target_concept_id = c.concept_id
),
both_mapping as (
  select * from sta_mapping
  union
  select * from shit_mapping
),
to_keep as (
  select concept_id, target_concept_id, 1 as keep_mapping
  from both_mapping
  where target_domain_id in (
    select is_domain from d
  )
  and target_domain_id <> 'Spec Anatomic Site' -- we don't move to the specimen table
  and target_domain_id <> 'Episode' -- we don't handle Episode yet
)
select concept_id, target_concept_id,
case 
when keep_mapping is not null then target_domain_id 
else 'Observation' 
end as target_domain_id
from both_mapping
left join to_keep using (concept_id, target_concept_id)
order by 1;

-- This table is for the partner-specific concept patch to fill the table to_value.
delete from @__results__.patch_to_value;
insert into @__results__.patch_to_value
with non_standard as (
  select concept_id
  from sta
  where critique = 'Not standard concept'
  and is_domain = 'Meas Value'
),
sta_mapping as (
  select s.concept_id, concept_id_2 as target_concept_id
  from non_standard s
  join @__vocab__.concept_relationship on s.concept_id = concept_id_1 
  and relationship_id = 'Maps to value' and concept_id_1 <> concept_id_2
  join @__vocab__.concept c on concept_id_2 = c.concept_id
  where standard_concept is not null
)
select concept_id, target_concept_id
from sta_mapping
order by 1;

-- This is for the partner-specific combi patch.
delete from @__results__.patch_combi;
insert into @__results__.patch_combi
with last_version as (
  select g.* 
  from @__results__.general g
  join @__results__.cur_version using(partner)
  where partner = '__partner_name__'
  and version = cur_general
)
select distinct cancer_id, histo_id, topo_id
from @__static__.cancer_histo_topo
join last_version h on histo_id = h.standard
join last_version t on topo_id = t.standard
order by cancer_id, topo_id, histo_id;

drop table if exists update_notes;
create temp table update_notes as
with non_standards as (
  select distinct concept_id
  from sta
  where critique = 'Not standard concept'
),
linked_ones as (
  select n.concept_id
  from non_standards n
  join @__vocab__.concept_relationship on n.concept_id = concept_id_1
  and relationship_id = 'Maps to' and concept_id_1 <> concept_id_2
  join @__vocab__.concept c on concept_id_2 = c.concept_id
  where standard_concept is not null
),
shitty as (
  select distinct concept_id
  from sta
  join @__results__.shit_list using(concept_id)
  where target_concept_id is null
)
select concept_id, 'Pending vocabulary update' as notes
from non_standards
left join linked_ones l using(concept_id)
where l.concept_id is null
union
select concept_id, 'Awaiting fix'
from shitty;

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
	  when source_is_standard is not null and source <> standard then 'Wrong mapping'
      when should.source is null and source_is_standard is null then 'No mapping available'
      else null
    end as critique,
    cnt, version
  from general_last_version
  join d using(domain) 
  left join @__vocab__.concept on concept_id=source
  left join should using(source)
  left join ismap using(source, standard)
  left join standard_sources using(source)
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
delete from @__results__.individual_concept_report i
using @__results__.cur_version v
where i.partner = v.partner
and i.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.individual_concept_report
with the_union as (
  select sta.*, notes
  from sta
  left join update_notes using(concept_id)
  where partner = '__partner_name__'
  union
  select *, null as notes from so
  where partner = '__partner_name__'
)
select * from the_union;

-- Source mapping for grade, stage and metastasis
delete from @__results__.cancer_modifiers c
using @__results__.cur_version v
where c.partner = v.partner
and c.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.cancer_modifiers
with inputs as (
  select partner, coalesce(source, 0) as source, coalesce(standard, 0) as standard,
  case when cnt = 0 then 1 else cnt end as cnt,
  version
  from general_last_version
),
totals as (
  select partner, sum(cnt) as all_total, version
  from inputs
  group by partner, version
),
critiques as (
  select partner, concept_id,
  case when records = 0 then 1 else records end as records
  from @__results__.individual_concept_report
  join @__results__.cur_version using(partner)
  where version = cur_general
  and concept = 'Source'
  and partner = '__partner_name__'
),
cats as (
  select 'Stage' as cat
  union
  select 'Grade' as cat
  union
  select 'Metastasis or lymph node involvement' as cat
),
cat_records as (
  select partner, source, 'Stage' as cat, sum(cnt) as cnt, version
  from inputs
  left join @__static__.all_stage s1 on source = s1.concept_id
  left join @__static__.all_stage s2 on standard = s2.concept_id
  where s1.concept_id is not null or s2.concept_id is not null
  group by partner, source, version
  union
  select partner, source, 'Grade' as cat, sum(cnt) as cnt, version
  from inputs
  left join @__static__.all_grade g1 on source = g1.concept_id
  left join @__static__.all_grade g2 on standard = g2.concept_id
  where g1.concept_id is not null or g2.concept_id is not null
  group by partner, source, version
  union
  select partner, source, 'Metastasis or lymph node involvement' as cat, sum(cnt) as cnt, version
  from inputs
  left join @__static__.all_met m1 on source = m1.concept_id
  left join @__static__.all_met m2 on standard = m2.concept_id
  where m1.concept_id is not null or m2.concept_id is not null
  group by partner, source, version
),
vocab_and_wrong as (
  select r.partner, source, cat, cnt as t_count, vocabulary_id, 
  case when source is null or source = 0 then 0 
       when coalesce(records, 0) > cnt then 0
       else cnt - coalesce(records, 0) 
	   end as r_count, 
  version
  from cat_records r
  join @__vocab__.concept c on source = c.concept_id
  left join critiques i on r.partner = i.partner and source = i.concept_id
),
grouped as (
  select partner, cat, vocabulary_id, sum(t_count) as total_count, sum(r_count) as correct_count, version
  from vocab_and_wrong
  group by partner, cat, vocabulary_id, version
),
basic_perc as (
  select partner, cat, vocabulary_id, total_count, correct_count, 
  round(correct_count * 100.0 / total_count, 2) as correct_perc, version
  from grouped
),
vocab_total as (
  select partner, cat, sum(total_count) as t_count, 
  sum(case when vocabulary_id = 'None' then 0 else total_count end) as v_count, -- valid ones, i.e. non-zero
  sum(correct_count) as c_count -- correctly mapped
  from basic_perc
  group by partner, cat
),
vocab_perc as (
  select partner, cat, vocabulary_id, total_count, correct_count, correct_perc,
  round(total_count * 100.0 / t_count, 2) as total_perc, version
  from basic_perc
  join vocab_total using (partner, cat)
)
select partner, cat, 'Total' as vocabulary_id, coalesce(t_count, 0) as total_count, 
coalesce(round(t_count * 100.0 / all_total, 2), 0.0) as total_perc, 
v_count as valid_count,
coalesce(round(v_count * 100.0 / t_count, 2), 0.0) as valid_perc,
coalesce(c_count, 0) as correct_count,
coalesce(round(c_count * 100.0 / case when v_count is null or v_count = 0 then null else v_count end, 2), 0.00) as correct_perc, version
from cats
join totals on 1 = 1
left join vocab_total using(partner, cat)
union
select partner, cat, vocabulary_id, total_count, total_perc, 0 as valid_count, 0 as valid_perc, 0 as correct_count, 
correct_perc, version
from vocab_perc
order by partner, cat, 3;


-- Summary for standard concepts
-- used to be "Standard summary report.txt"
delete from @__results__.standard_summary_report s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.standard_summary_report
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
delete from @__results__.source_summary_report s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.source_summary_report
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
    where critique in ('Concept NULL', 'Concept 0', '2-Billionaire', 'Concept unknown', 'No mapping available')
  )
  group by partner, critique, version
)
select partner, critique, records, round(records*1.0/t_records, 4) as "record_%", version
from cst_summed join cnts using(partner)
where partner = '__partner_name__'
order by 1, 2;

-- Summary mapping report
-- used to be "Mapping summary report.txt"
delete from @__results__.mapping_summary_report s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.mapping_summary_report
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

insert into @__results__.rolled_up_tumor_types
select *
from temp_tumor_types;

-- critique only standard concepts related to patch
drop table if exists general_last_version;
create temp table general_last_version as
select g.*
from @__results__.general_cleaned g
join @__results__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

drop table if exists domain_links;
create temp table domain_links as
with all_data as (
  select partner, concept_id as standard, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, sum(cnt) as records, version
  from general_last_version
  join d using(domain)
  join @__vocab__.concept on concept_id=standard
  group by partner, concept_id, concept_name, vocabulary_id, domain_id, is_domain, standard_concept, version
),
valid_target as ( -- concepts belonging to a regular domain (that a table exists for)
  select standard, 1 as can_map
  from all_data
  where domain_id in (
    select is_domain from d
	where is_domain <> 'Spec Anatomic Site'
  )
)
select distinct partner, standard, concept_name, vocabulary_id, domain_id, 
is_domain, standard_concept,
case when is_domain = 'Spec Anatomic Site' or is_domain != domain_id and (is_domain <> 'Observation' or can_map is not null) then 1 else null end as wrong_domain,
records, version
from all_data
left join valid_target using(standard)
;

-- critique standard concepts
drop table if exists crit_sta;
create temp table crit_sta as
with overloaded_concepts as (
  select concept_id_2 
  from @__vocab__.concept_relationship 
  where relationship_id='Has Answer'
  and invalid_reason is null 
  and concept_id_1 in (3020133, 3010621, 3020306, 40769814, 3043806, 40758258, 36203250, 40769831, 21494849, 3042720, 42527705, 3015048, 46236987, 46236986, 46235142, 3001410, 1091494, 3028485, 36304519, 3045092, 42527788, 3046070, 3047311, 3043846, 3043017, 40769849, 42527700, 3045426, 3019341, 3021037, 3002943, 40770067, 3017327, 3006171, 3032860, 3032820, 3032529, 3046523, 44816728, 36203176, 1617409, 1616763, 3002377, 36203154, 36203137, 1617315, 3043693, 36203118, 36203117, 36203124, 21494733, 3014845, 21492981, 1616553, 36305168, 3046972, 3044365, 3046527, 3045602, 21494735, 1616306, 3044724, 3042773, 3047277, 42527790, 40769833, 21491882, 21491880, 21491879, 21491881, 36204404, 21493968, 21493970, 21493971, 36031181, 42529177, 36031552, 21493969, 42527723, 42527720, 36203139, 21494724, 40762606, 3046434, 3008250, 3006038, 3007073, 3016292, 3046598, 36203181, 3047346, 3046361, 37020347, 42527712, 42527711, 36203169, 1617504, 1616523, 21493980, 21493979, 21493974, 21493976, 21493977, 21493975, 21493981, 40765594, 21493978, 21491883, 21490957, 3000766, 21494730)
),
value_needs_mapping as (
  select concept_id_2 
  from @__vocab__.concept_relationship 
  where relationship_id='Has Answer'
  and invalid_reason is null 
  and concept_id_1 in (3040950, 36031424, 44786879, 36204549, 44786934, 46235351, 3050686, 40760326, 40770159, 40770163, 3015763, 3026214, 3023877, 40766660, 1617452, 1616716, 40769855, 3019275, 3022835, 3000608, 3019130, 40766623, 40766625, 3003037, 21494723, 36204558, 1001824, 36305514, 36306187, 21491888, 21491887, 3051348, 40766653, 42527886, 40769122, 3012604, 36203179, 40769857, 40769820, 3001285, 36203138, 36305408, 36305927, 21491872, 3046315, 40771030, 40770927, 40770932, 42529083, 44786707, 44786708, 1989065, 42870406, 3004250, 21491611, 40769265, 3009329, 3038982, 3033619, 3034828, 3014280, 3027596, 3021444, 21494722, 3016725, 46235213, 3051551, 44816596, 3008181, 36203126, 1617595, 3043591, 36660206, 3006575, 40769842, 40769838, 21493972, 40762591, 3007727, 42528924, 3022698, 3018082, 3008495, 3016308, 3008841, 3027109, 40769836, 40769840, 3020821, 3021034, 42527715)
),
crit_sta as (
  select partner, 'Standard' as concept, standard as concept_id, concept_name, vocabulary_id, domain_id, is_domain,
    case 
      when standard is null then 'Concept NULL'
      when standard=0 then 'Concept 0'
      when vocabulary_id='NAACCR' and concept_name ilike '%unknown%' then 'Flavor of NULL'
      when vocabulary_id='NAACCR' and concept_name ilike '%not stated%' then 'Flavor of NULL'
      when domain_id='Meas Value' and concept_name in ('Unknown', 'Not staged', 'Other', 'Other, NOS', 'Unknown term', 'Does not apply', 'Not applicable', 'Not Applicable', 'Not detected', 'N/A', 'Refused', 'No', 'Not specified', 'No tumor', 'Invalid', 'Other cancer-directed therapy recommended, unknown if administered', 'Don''t know', 'None', 'Not asked', 'No information', 'Unable to determine', 'Don''t know/refused', 'Patient refused', 'Not tested', 'Resident refused', 'Asked but unknown', 'Refused to answer') then 'Flavor of NULL'
-- list of invalid grade concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_grade) then 'Invalid grade'
-- list of invalid stage concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_stage) then 'Invalid stage'
-- list of invalid met or node concepts, mostly from NAACCR
      when standard in (select concept_id from @__static__.invalid_met) then 'Invalid met or node'
      when standard in (select concept_id from @__static__.split_conditions) then 'Condition needs splitting'
      when is_domain='Meas Value' and standard in (select concept_id_2 from value_needs_mapping) then 'Value needs mapping'
      when coalesce(standard_concept, 'C')='C' then 'Not standard concept'
      when wrong_domain is not null then 'Wrong domain table'
      when is_domain='Meas Value' and standard in (select concept_id_2 from overloaded_concepts) then 'Value needs pre-coord mapping'
      else null 
    end as critique, 
    records, version
  from domain_links
-- see if LOINC value, which needs to be pre-coordinated
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

delete from @__results__.standard_summary_report_cleaned s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.standard_summary_report_cleaned
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
join @__results__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

delete from @__results__.histo_topo_percent h
using @__results__.cur_version v
where h.partner = v.partner
and h.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.histo_topo_percent
with oneleggeds as (
  select partner, sum(cnt) as onelegged
  from general_last_version
  join @__static__.onelegged_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
shallows as (
  select partner, sum(cnt) as shallow
  from general_last_version
  join @__static__.shallow_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
totals as (
  select partner, sum(cnt) as total
  from general_last_version
  join @__static__.all_cancer on standard = concept_id
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
from @__results__.patient
join @__results__.cur_version using(partner)
left join totals using(partner)
left join oneleggeds using(partner)
left join shallows using(partner)
left join both_sides using(partner)
where partner = '__partner_name__'
and version = cur_general;

delete from @__results__.histo_topo_individual h
using @__results__.cur_version v
where h.partner = v.partner
and h.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.histo_topo_individual
with concepts as (
  select partner, standard as concept_id, 'One-legged cancer' as critique, sum(cnt) as records, version
  from general_last_version
  join @__static__.onelegged_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner, standard, version
  union
  select partner, standard, 'Shallow cancer' as critique, sum(cnt), version
  from general_last_version
  join @__static__.shallow_cancer on standard = concept_id
  where partner = '__partner_name__'
  group by partner, standard, version
)
select partner, concept_id, concept_name, critique, records, version
from concepts
join @__vocab__.concept using (concept_id)
order by partner, critique, concept_id;

-- Stages

delete from @__results__.stages s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into @__results__.stages
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_last_version
  join @__static__.invalid_stage on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_last_version
  join @__static__.all_stage on standard = concept_id
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
from @__results__.patient
join @__results__.cur_version using(partner)
left join bads using (partner)
left join wholes using (partner)
left join totals using (partner)
where partner = '__partner_name__'
and version = cur_general
;

-- Grades

delete from @__results__.grades g
using @__results__.cur_version v
where g.partner = v.partner
and g.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into @__results__.grades
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_last_version
  join @__static__.invalid_grade on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_last_version
  join @__static__.all_grade on standard = concept_id
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
from @__results__.patient
join @__results__.cur_version using(partner)
left join bads using (partner)
left join wholes using (partner)
left join totals using (partner)
where partner = '__partner_name__'
and version = cur_general
;

-- Metastases

delete from @__results__.mets m
using @__results__.cur_version v
where m.partner = v.partner
and m.partner = '__partner_name__'
and version = cur_general;

-- This creates an overview of one record per partner.
-- It contains the number of records and percentages. See below for details.
insert into @__results__.mets
with bads as ( -- bad records of the category
  select partner, sum(cnt) as bad
  from general_last_version
  join @__static__.invalid_met on standard = concept_id
  where partner = '__partner_name__'
  group by partner
),
wholes as ( -- all records of the category, regardless of correctness
  select partner, 
  case sum(cnt) when 0 then null else sum(cnt) end as whole_cat
  from general_last_version
  join @__static__.all_met on standard = concept_id
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
from @__results__.patient
join @__results__.cur_version using(partner)
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
from @__results__.general g
join @__results__.cur_version using(partner)
where partner = '__partner_name__'
and version = cur_general;

-- create denominators for concepts and values
drop table if exists general_counts;
create temp table general_counts as
select partner, category as cat, sum(cnt) as denom
from @__static__.lab_category
join general_last_version on standard=concept_id
where partner = '__partner_name__'
group by partner, cat;

drop table if exists measurement_last_version;
create temp table measurement_last_version as
select m.*
from @__results__.measurement m
join @__results__.cur_version using(partner)
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
  join @__static__.lab_category c on c.concept_id=r.measurement_concept_id
  join @__vocab__.concept m on m.concept_id=r.measurement_concept_id
  join @__vocab__.concept v on v.concept_id=r.value_as_concept_id
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
with normals (cat, unit, range_low, range_high, matching) as (values
  ('ALT', 'unit per liter', 7, 56, 'upper'),
  ('ANC', 'thousand per microliter', 1.5, 8.0, 'both'),
  ('ANC', 'per microliter', 1500, 8000, 'both'),
  ('ANC', 'percent', 40, 70, 'both'),
  ('aPTT', 'second', 25, 35, 'both'),
  ('AST', 'unit per liter', 10, 40, 'upper'),
  ('CrCl', 'milliliter per minute', 88, 137, 'both'),
  ('Creatinine', 'gram per deciliter', 0.0006, 0.0013, 'both'),
  ('Creatinine', 'microgram per deciliter', 600, 1300, 'both'),
  ('Creatinine', 'microgram per liter', 6000, 13000, 'both'),
  ('Creatinine', 'micromole per liter', 53, 115, 'both'),
  ('Creatinine', 'milligram per deciliter', 0.6, 1.3, 'both'),
  ('Creatinine', 'milligram per liter', 6, 13, 'both'),
  ('Creatinine', 'milligram per milliliter', 0.006, 0.013, 'both'),
  ('Creatinine', 'millimmole per liter', 0.053, 0.115, 'both'),
  ('Direct bilirubin', 'micromole per liter', 0.01, 5, 'upper'),
  ('Direct bilirubin', 'milligram per deciliter', 0.01, 0.3, 'uppper'),
  ('GFR', 'liter per minute per square meter', 0.052, 0.052, 'lower'),
  ('GFR', 'milliliter per minute per 1.73 square meter', 90, 90, 'lower'),
  ('HbA1c', 'millimole per mole', 25, 39, 'upper'),
  ('HbA1c', 'percent', 4, 5.7, 'upper'),
  ('Hemoglobin', 'gram per deciliter', 12.0, 17.5, 'both'),
  ('Hemoglobin', 'gram per liter', 120.0, 170.5, 'both'),
  ('Hemoglobin', 'millimole per liter', 7.4, 10.8, 'both'),
  ('INR', 'ratio', 0.8, 1.2, 'both'),
  ('Platelets', 'million per microliter', 0.15, 0.45, 'both'),
  ('Platelets', 'ten thousand per microliter', 15, 45, 'both'),
  ('Platelets', 'thousand per liter', 150000, 450000, 'both'),
  ('Platelets', 'thousand per microliter', 150, 450, 'both'),
  ('PT', 'second', 11, 13.5, 'both'),
  ('Total bilirubin', 'micromole per liter', 5, 21, 'both'),
  ('Total bilirubin', 'milligram per deciliter', 0.3, 1.2, 'both')
),
p (a_name, u_name) as (values
  ('percent hemoglobin A1c', 'percent'),
  ('per 100 white blood cells', 'percent'),
  ('percent of white blood cells', 'percent'),
  ('cells per microliter', 'per microliter'),
  ('billion per liter', 'thousand per microliter'),
  ('billion per liter', 'million per milliliter'),
  ('thousand per cubic millimeter', 'thousand per microliter'),
  ('nanomole per milliliter', 'micromol per liter'),
  ('microgram per milliliter', 'milligram per liter'),
  ('international unit per liter', 'unit per liter')
),
-- permute ranges with different but equivalent units
unit_cat as (
  select cat, unit, unit as a_unit from normals
union
  select cat, unit, a_name from normals join p on u_name=unit
),
-- prepare values: remove negatives and zeros
prep_val as (
  select row_number() over () as row_id, partner, cat, m_id, m_name, u_id, u_name, range_low, range_high, p_03, p_25, 
  median, p_75, p_97, sum(cnt) as records, version from (
    select partner, category as cat, r.measurement_concept_id as m_id, m.concept_name as m_name, unit_concept_id as u_id, u.concept_name as u_name,
      case when range_low<=0 then null else range_low end as range_low,
      case when range_high<=0 then null else range_high end as range_high,
      case when p_03<=0 then null else p_03 end as p_03,
      case when p_25<=0 then null else p_25 end as p_25,
      case when median<=0 then null else median end as median,
      case when p_75<=0 then null else p_75 end as p_75,
      case when p_97<=0 then null else p_97 end as p_97,
      coalesce(cnt, 1) as cnt, version
    from measurement_last_version r
    join @__static__.lab_category c on c.concept_id=r.measurement_concept_id
	join @__vocab__.concept m on m.concept_id=r.measurement_concept_id
    left join @__vocab__.concept u on u.concept_id=unit_concept_id
  )
  where u_id!=0 or coalesce(u_id, range_low, range_high, p_03, p_25, median, p_75, p_97) is not null
  group by partner, cat, m_id, m_name, u_id, u_name, range_low, range_high, p_03, p_25, median, p_75, p_97, version
),
-- compare ranges to standard ranges in normals
score_range as (
  select row_id, unit from ( -- pick optimal unit, if any, and leave only row_id for later join
    select *,
    min(decade) over (partition by partner, m_id, range_low, range_high) as min_decade -- lowest decade is best
    from (
      select v.*, n.unit,
      case
        -- two-sided: center-to-center provided to expected range
        when matching='both' and v.range_low<v.range_high
          then abs((log(n.range_low)+log(n.range_high))/2 - (log(v.range_low)+log(v.range_high))/2)
        -- upper-only: distance from provided to expected
        when matching='upper' and v.range_high is not null
          then abs((log(n.range_high)-log(v.range_high)))
        -- lower-only: distance from provided to expected
        when matching='lower' and v.range_low is not null
          then abs((log(n.range_low)-log(v.range_low)))
        else null
      end as decade -- range decade, 0=perfect, >0.7 mismatch
      from prep_val v
      join normals n using(cat)
    ) 
  )
  where decade=min_decade and decade<0.7 -- only pick the best one and if it is close enough to expected
),
score_dist as (
  select row_id, unit from (
    select *,
    min(decade) over (partition by partner, m_id, p_03, p_25, median, p_75, p_97) as min_decade
    from (
      select v.*, n.unit,
      case n.matching
        -- two-sided: center of range to percentiles comparison
        when 'both' then abs((log(n.range_low)+log(n.range_high))/2 - (log(p_25)+log(p_75))/2)
        -- upper-only: distance from U to the patient span
        when 'upper' then greatest(0, log(n.range_high)-log(p_97), log(p_03)-log(n.range_high))
        -- lower-only: distance from L to the patient span
        when 'lower' then greatest(0, log(n.range_low)-log(p_97), log(p_03)-log(n.range_low))
        else null
      end as decade -- range decade, 0=perfect, >0.7 mismatch
      from prep_val v
      join normals n using(cat)
    ) 
  )
  where decade=min_decade and decade<0.7 -- only pick the best one and if it is close enough to expected
),
value_tot as (
  select partner, sum(records) as total
  from prep_val
  group by partner
)
select * from (
  select distinct partner, version, v.cat, m_id, m_name, u_id, v.u_name, v.range_low, v.range_high, p_03, p_25, median, p_75, p_97, records, 100.0*records/total as pct_val_rcs,
  case when sr.row_id is null then 'Unusable' else null end as range, -- check if provided range is useful
  case when sd.row_id is null then 'Unusable' else null end as distribution, -- check if distribution is useful
  case when p_97 is null or p_97=0 then 'Missing' else null end as values, -- if values are not provided
  case when p_03=p_97 then 'Small' else null end as spread, -- check if no spread in distribution
  -- If inferred unit from range or distribution matches provided unit or possible unit
  case
    when sr.row_id is not null and v.u_name in (select a_unit from unit_cat where unit_cat.unit=sr.unit) then null
    when sd.row_id is not null and v.u_name in (select a_unit from unit_cat where unit_cat.unit=sd.unit) then null
    when v.u_name in (select a_unit from unit_cat where unit_cat.cat=v.cat) or v.u_name in (select unit from unit_cat where unit_cat.cat=v.cat) then null
    else 'Bad' end as unit,
  -- Outliers measured as the spread > 1000x or if there are 9999 in the values
    case when cast(p_97 as text) like '9999%' or p_25>0 and
       p_97/coalesce(case v.range_high when 0 then null else v.range_high end, p_25)>1000.0 then 'Present' else null end as outliers
  from prep_val v
  join value_tot using(partner)
  left join score_range sr using(row_id)
  left join score_dist sd using(row_id)
)
--where coalesce(range, distribution, values, spread, unit, outliers) is not null
;

-- long lab report
delete from @__results__.lab_long_report l
using @__results__.cur_version v
where l.partner = v.partner
and l.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.lab_long_report (partner, cat, measurement_id, measurement_name, records, percent,
  p_03, p_25, median, p_75, p_97, value_id, value_name, concept_critique, pct_of_concept_recs,
  unit_id, unit_name, range_low, range_high, range, distribution, values, spread, unit, outliers, pct_of_value_recs, version)
with long_report as (
  -- report on value distribution
  select partner, cat, m_id as measurement_id, m_name as measurement_name, records, 100.0*records/denom as percent, 
  -- the original percentiles
  p_03, p_25, median, p_75, p_97,
  -- critique on value_as_concept_id
  null as value_id, null as value_name, null as concept_critique, null as pct_of_concept_recs,
  -- critique on distribution of values
  u_id as unit_id, u_name as unit_name, range_low, range_high, range, distribution, values, spread, unit, outliers, pct_val_rcs as pct_of_value_recs, version
  from value_long_report
  join general_counts using(partner, cat)
  union
  -- add report from value as concepts
  select partner, cat, m_id, m_name, records, 100.0*records/denom as percent, 
  null, null, null, null, null,
  v_id, v_name, critique, pct_con_rcs, 
  null, null, null, null, null, null, null, null, null, null, null, version
  from concept_long_report
  join general_counts using(partner, cat)
  where critique!='Good' and critique is not null
)
select * from long_report
order by partner, cat, measurement_name, value_name, unit_name, range_low, range_high;

-- summary lab report
delete from @__results__.lab_summary s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.lab_summary (partner, cat, concept_records, number, flavor_null, precoordinated,
measurement, not_value, pct_usable_consets, value_records, bad_unit, bad_range, bad_dist, missing_values,
no_spread, outliers, pct_usable_valsets, version)
with cur_version as (
  select cur_general as g_version
  from @__results__.cur_version
),
all_cat as (
  select distinct '__partner_name__' as partner, category as cat, g_version
  from @__static__.lab_category
  join cur_version on 1 = 1
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
    sum(case when distribution is null then 0 else records end) as bad_dist,
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
  case bad_dist when 0 then null else bad_dist end as bad_dist,
  case missing_values when 0 then null else missing_values end as missing_values,
  case no_spread when 0 then null else no_spread end as no_spread,
  case outliers when 0 then null else outliers end as outliers,
  100.0*(value_records-coalesce(hopeless, 0))/value_records as pct_usable_valsets,
  coalesce(v_version, c_version, g_version) as version
from all_cat
left join concept_summary using(partner, cat)
left join value_summary using(partner, cat)
order by partner, cat;


delete from @__results__.special_conditions s
using @__results__.cur_version v
where s.partner = v.partner
and s.partner = '__partner_name__'
and version = cur_general;

insert into @__results__.special_conditions
with ecogs as (
  select partner, 'ECOG' as critique, sum(cnt) as records, version
  from measurement_last_version
  join @__static__.lab_category on concept_id = measurement_concept_id
  where partner = '__partner_name__'
  and category = 'ECOG'
  group by partner, version
),
karnofskys as (
  select partner, 'Karnofsky' as critique, sum(cnt) as records, version
  from measurement_last_version
  join @__static__.lab_category on concept_id = measurement_concept_id
  where partner = '__partner_name__'
  and category = 'Karnofsky'
  group by partner, version
),
pd_l1s as (
  select partner, 'PD-L1' as critique, sum(cnt) as records, version
  from measurement_last_version
  join @__static__.lab_category on concept_id = measurement_concept_id
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
