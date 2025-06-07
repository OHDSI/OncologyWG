/* uses placeholders
   __cdm_schema__ - the schema containing the vocabulary tables (concept, etc.)
*/

/*****************************
1. Define concepts for general
*****************************/
-- create list of concept for general. It contains any clinical concept, but no episodes and no genomic markers.
with loinc_stages(concept_id) as (values
  (3008495), (3022698), (3027109), (21490957), (21491883)
),
loinc_grades(concept_id) as (values
  (3019275), (3022835), (3042773), (3044724), (3047277), (3047285), (36660173), (36660206), (40762604), (42527714), (42527790)
),
snomed as (
  select descendant_concept_id as concept_id from __cdm_schema__.concept_ancestor where ancestor_concept_id in (37163866, 37168578, 4216788, 4264604)
),
co as (
  select concept_id from __cdm_schema__.concept where concept_name ilike '%cancer%' 
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%metasta%' 
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%carcino%' 
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%malignan%' 
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%neoplas%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%tumor%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '% onco%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%biops%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%debulk%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%chemotherap%'
  union select concept_id from __cdm_schema__.concept where concept_name ilike '%radiotherap%'
  union select concept_id from __cdm_schema__.concept where vocabulary_id in ('ICDO3', 'CAP', 'NAACCR', 'Cancer Modifier', 'OncoTree', 'HemOnc')
  union select concept_id from __cdm_schema__.concept where vocabulary_id in ('ICD10', 'ICD10CM', 'ICD10GM', 'CIM10') and concept_code like 'C%'
-- LOINC stages - questions of cancer stages
  union select * from loinc_stages
-- and answers 
  union select distinct concept_id_1 from __cdm_schema__.concept_relationship join loinc_stages on concept_id=concept_id_2 where relationship_id='Answer of'
-- LOINC grades - questions of cancer grades
  union select * from loinc_grades
-- and answers 
  union select distinct concept_id_1 from __cdm_schema__.concept_relationship join loinc_grades on concept_id=concept_id_2 where relationship_id='Answer of'
-- SNOMED stages and grades
  union select * from snomed
  union select concept_id_2 from snomed join __cdm_schema__.concept_relationship on concept_id=concept_id_1 and relationship_id='Concept replaces'
-- Drug descendants of ATC L "Antineoplastic and immunomodulating agents", double hop through ingredients to avoid ancestry trimming
  union select distinct a2.descendant_concept_id concept_id from __cdm_schema__.concept_ancestor a1 join __cdm_schema__.concept c1 on c1.concept_id=a1.descendant_concept_id and c1.vocabulary_id in ('RxNorm', 'RxNorm Extension') and c1.concept_class_id='Ingredient' 
    join __cdm_schema__.concept_ancestor a2 on a2.ancestor_concept_id=concept_id join __cdm_schema__.concept c2 on c2.concept_id=a2.descendant_concept_id and c2.concept_class_id in ('Ingredient', 'Multiple Ingredients', 'Clinical Drug Form', 'Branded Drug Form', 'Clinical Drug Comp', 'Branded Drug Comp', 'Clinical Drug', 'Branded Drug', 'Quant Clinical Drug', 'Quant Branded Drug', 'ATC 5th')
  where a1.ancestor_concept_id=21601386 
),
cc as ( -- add all concepts mapping into the above
  select concept_id from (
    select * from co
    union
    select concept_id_2 from __cdm_schema__.concept_relationship join co on concept_id=concept_id_1 where invalid_reason is null and relationship_id='Mapped from' and concept_id_1!=concept_id_2
  ) a join __cdm_schema__.concept using(concept_id)
  where vocabulary_id not in -- kick out vocabularies we are not wrestling with
    ('Indication', 'Concept Class', 'ISBT Attribute', 'ETC', 'ISBT', 'SMQ', 'SNOMED Veterinary', 'Relationship', 'Vocabulary', 'CO-CONNECT MIABIS', 'MeSH', 'NDFRT', 'Nebraska Lexicon', 'EDI', 'ICD10CN', 'KCD7', 'CO-CONNECT TWINS', 'UB04 Pt dis status', 'ATC', 'VA Class', 'GGR', 'OMOP Extension', 'Multilex', 'EphMRA ATC', 'AMIS', 'Meas Type', 'HES Specialty', 'MDC', 'VANDF', 'Condition Type'))
select * from cc
union 
select * from static.all_cancer
order by concept_id;
