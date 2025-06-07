-- This script creates four tables (metastatic_cancer, onelegged_cancer, shallow_cancer, all_cancer) 
-- that contain concepts. These are used to calculate how many percent of all histo/topo-related 
-- records in a database are fall into the three sub categories. (The denominator is all_cancer.)
--  The content of the four tables above should remain static as long as the vocabulary isn't updated.

-- Create valid SNOMED solid (not hem) malignant and in situ cancer conditions 
drop table if exists snomed_solids;
create temp table snomed_solids as 
select concept_id as cancer_id, concept_code as cancer_code, concept_name as cancer_name
from prodv5.concept
join prodv5.concept_ancestor malignant on malignant.descendant_concept_id=concept_id and malignant.ancestor_concept_id in (433435, 443392) -- carcinoma in siut, malignant neoplasm
left join prodv5.concept_ancestor hem on hem.descendant_concept_id=concept_id and hem.ancestor_concept_id in (4189640, 4212328) -- hem tumors
where vocabulary_id='SNOMED' and domain_id='Condition' and standard_concept='S'
and hem.descendant_concept_id is null;

-- Create valid ICDO solid (not hem) malignant and in situ cancer conditions 
drop table if exists icdo_solids;
create temp table icdo_solids as 
select concept_id as cancer_id, concept_code as cancer_code, concept_name as cancer_name
from prodv5.concept
where vocabulary_id='ICDO3' and domain_id='Condition' and standard_concept='S'
  and concept_code not like '%/0%' and concept_code not like '%/1%' -- no benigns
  and concept_code not like '%C42.0' -- no blood
  and concept_code not like '%C42.1' -- no bone marrow
;

-- pairs of above conditions and valid histologies
drop table if exists histos;
create temp table histos as -- condition-histo pairs
with icdo_only as ( -- ICDO cancers to ICDO histos
  select cancer_id, cancer_code, cancer_name,
    histo.concept_id as histo_id, histo.concept_code as histo_code, histo.concept_name as histo_name
  from icdo_solids
  join prodv5.concept_relationship r1 on r1.concept_id_1=cancer_id and r1.invalid_reason is null and r1.relationship_id='Has Histology ICDO'
  join prodv5.concept_relationship r2 on r2.concept_id_1=r1.concept_id_2 and r2.invalid_reason is null and r2.relationship_id='Maps to'
  join prodv5.concept histo on histo.concept_id=r2.concept_id_2 and histo.vocabulary_id='ICDO3' and histo.standard_concept='S' 
)
-- SNOMED cancers to SNOMED histos
  select cancer_id, cancer_code, cancer_name,
    histo.concept_id as histo_id, histo.concept_code as histo_code, histo.concept_name as histo_name
  from snomed_solids
  join prodv5.concept_relationship r1 on r1.concept_id_1=cancer_id and r1.invalid_reason is null and r1.relationship_id='Has asso morph'
  join prodv5.concept_relationship r2 on r2.concept_id_1=r1.concept_id_2 and r2.invalid_reason is null and r2.relationship_id='Maps to'
  join prodv5.concept histo on histo.concept_id=r2.concept_id_2 and histo.vocabulary_id='SNOMED' and histo.standard_concept='S' 
union
select * from icdo_only
union
-- ICDO cancers to SNOMED histos - only if ICDO histos don't exist
  select cancer_id, cancer_code, cancer_name,
    histo.concept_id as histo_id, histo.concept_code as histo_code, histo.concept_name as histo_name
  from icdo_solids 
  join prodv5.concept_relationship r1 on r1.concept_id_1=cancer_id and r1.invalid_reason is null and r1.relationship_id='Has asso morph'
  join prodv5.concept_relationship r2 on r2.concept_id_1=r1.concept_id_2 and r2.invalid_reason is null and r2.relationship_id='Maps to'
  join prodv5.concept histo on histo.concept_id=r2.concept_id_2 and histo.vocabulary_id='SNOMED' and histo.standard_concept='S' 
  and cancer_id not in (select cancer_id from icdo_only)
;

-- all pairs of above conditions and valid topographies
drop table if exists topos;
create temp table topos as -- condition-topo pairs
with icdo_only as ( -- ICDO cancers to ICDO topos
  select cancer_id, cancer_code, cancer_name,
    topo.concept_id as topo_id, topo.concept_code as topo_code, topo.concept_name as topo_name
  from icdo_solids
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and r.relationship_id='Has Topography ICDO'
  join prodv5.concept topo on topo.concept_id=r.concept_id_2 and topo.vocabulary_id='ICDO3' and topo.standard_concept='S' 
)
-- SNOMED cancers to SNOMED topos
  select cancer_id, cancer_code, cancer_name, -- for SNOMEDs
    topo.concept_id as topo_id, topo.concept_code as topo_code, topo.concept_name as topo_name
  from snomed_solids
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and r.relationship_id='Has finding site'
  join prodv5.concept topo on topo.concept_id=r.concept_id_2 and topo.vocabulary_id='SNOMED' and topo.standard_concept='S'
union
  select * from icdo_only -- for ICDOs with ICDO topos
union
-- ICDO cancers to SNOMED topos - if no ICDO topos exist
  select cancer_id, cancer_code, cancer_name, -- for ICDOs with SNOMED topos
    topo.concept_id as topo_id, topo.concept_code as topo_code, topo.concept_name as topo_name
  from icdo_solids
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and r.relationship_id='Has finding site'
  join prodv5.concept topo on topo.concept_id=r.concept_id_2 and topo.vocabulary_id='SNOMED' and topo.standard_concept='S' 
  and cancer_id not in (select cancer_id from icdo_only)
;

-- all metastatic conditions
drop table if exists static.metastatic_cancer;
create table static.metastatic_cancer as
select cancer_id as concept_id from histos
where histo_name ilike '%metasta%' and histo_name not like '%ncertain whether primary or metastatic%'
union
select cancer_id from histos
where cancer_name ilike '%metasta%' and cancer_name not like '%ncertain whether primary or metastatic%'
;

-- standard and non-standard cancer condition concepts with no topo and their histo counterpart  
drop table if exists static.onelegged_cancer;
create table static.onelegged_cancer as
with onelegged_histo as (
  select cancer_id
  from histos
  left join topos using(cancer_id)
  where topos.cancer_id is null and histos.cancer_code not like '%-C%'
  and histo_id not in (37156895, 37153816, 4032806, 433435) -- exclude zero-legged malignant neoplasm, metastatic malignant neoplasm, carcinoma in situ
  or histos.cancer_code like '%NULL' or histos.cancer_code like '%C76.7' -- ill-defined sites)
)
  select cancer_id as concept_id from onelegged_histo
union -- add all those that used to be valid and are mapped over
  select concept_id
  from onelegged_histo
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and relationship_id in ('Mapped from', 'Concept replaces', 'Concept was_a from') and concept_id_1!=concept_id_2
  join prodv5.concept on concept_id=r.concept_id_2 and vocabulary_id in ('SNOMED', 'ICDO3')
    and concept_code not like '%C49.9' and concept_code not like '%C72.9' and concept_code not like '%C42.0' and concept_code not like '%C80.9'
    and concept_code not like '%C44.9'
;

-- standard and non-standard cancer condition concepts with generic histo and their topo counterpart  
drop table if exists static.shallow_cancer;
create table static.shallow_cancer as
with shallow_topo as (
  select cancer_id
  from topos
  join histos using(cancer_id)
  where histo_id in (37156895, 37153816, 4032806, 433435) -- malignant neoplasm, metastatic malignant neoplasm, carcinoma in situ
  or topos.cancer_code like 'NULL%'
)
  select cancer_id as concept_id from shallow_topo
union  -- add all those that used to be valid and are mapped over
  select concept_id
  from shallow_topo
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and relationship_id in ('Mapped from', 'Concept replaces', 'Concept was_a from') and concept_id_1!=concept_id_2
  join prodv5.concept on concept_id=r.concept_id_2 and vocabulary_id in ('SNOMED', 'ICDO3')
;

drop table if exists static.all_cancer;
create table static.all_cancer as
with standard_cancer as (
  select cancer_id from snomed_solids
union
  select cancer_id from icdo_solids
)
  select cancer_id as concept_id from standard_cancer
union -- add all those that used to be valid and are mapped over
  select concept_id
  from standard_cancer
  join prodv5.concept_relationship r on r.concept_id_1=cancer_id and r.invalid_reason is null and relationship_id in ('Mapped from', 'Concept replaces', 'Concept was_a from') and concept_id_1!=concept_id_2
  join prodv5.concept on concept_id=r.concept_id_2 and vocabulary_id in ('SNOMED', 'ICDO3')
;
