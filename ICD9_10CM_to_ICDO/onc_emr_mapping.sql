--1. easiest , behaviour = 3, histology is not null, vocabulary = icd10cm -> to concatenate 
--Note, when Histology is empty the behaviour is described in ICD9/10CM code
create table oemr_map_v0 as 
select i.concept_name as icd_name,h.concept_name as histology_name,    a.*, b.concept_id as source_concept_id, b.concept_code as source_value, 
c.*
 from (
select 
case
 when length (icd_code) = 3 then  histology_code || '/' || behavior ||'-' || substring (icd_code, 1, 5) ||'.9'
when icd_code in ('C64.2', 'C64.1') then  histology_code || '/' || behavior ||'-' || 'C64.9'
when icd_code in ('C43.5')  then  histology_code || '/' || behavior ||'-' || 'C44.5'
else histology_code || '/' || behavior ||'-' || substring (icd_code, 1, 5) end

 as source_concept_code, *
 from oncemr_combo where behavior = 3 and histology_code is not null and diag_vers_typ_id = 2
 ) a 
 join  concept i on i.concept_code = icd_code and  i.vocabulary_id = 'ICD10CM'
 join  concept h on h.concept_code =  histology_code || '/' || behavior and h.vocabulary_id ='ICDO3'
 join concept b on a.source_concept_code = b.concept_code and b.vocabulary_id = 'ICDO3'
 join concept_relationship r on r.concept_id_1 = b.concept_id and relationship_id ='Maps to'
 join concept c on c.concept_id = r.concept_id_2 
;
--2. Attribute based approach, which covers any behaviour / ICDversion / histology if such present in our vocabulary
create table onc_emr_mapped as
select 
a.*, t.*
 from oncemr_combo a
join concept i on i.concept_code = icd_code and ( diag_vers_typ_id = 1 and i.vocabulary_id = 'ICD9CM' or diag_vers_typ_id = 2 and i.vocabulary_id = 'ICD10CM') -- get ICD9/10 concept_id
join concept_relationship rm on i.concept_id = rm.concept_id_1 and rm.relationship_id ='Maps to' and rm.invalid_reason is null-- get the SNOMED mapping
join concept_relationship st on rm.concept_id_2= st.concept_id_1 and st.relationship_id ='Has finding site' -- get the SNOMED mapping (st.concept_id_2 = SNOMED topography')
join concept h on h.concept_code =  histology_code || '/' || behavior and h.vocabulary_id ='ICDO3' -- get the histology concept (h.concept_id)
join concept_relationship hm on h.concept_id = hm.concept_id_1 and hm.relationship_id = 'ICDO - SNOMED' -- get the histology mapping (hm.concept_id_2)
join concept_relationship ts on st.concept_id_2 = ts.concept_id_1 and ts.relationship_id ='Finding site of' -- get the target concept by topography (ts.concept_id_2)
join concept_relationship hs on hm.concept_id_2= hs.concept_id_1 and hs.relationship_id ='Asso morph of' 
join concept t on hs.concept_id_2  = t.concept_id
where hs.concept_id_2 = ts.concept_id_2
;
--1st approach is more straightforward and less ambigous
--keep its results as primary

--3. deduping attribute based approach mappings
--take the shortest term as a best one
select distinct icd_code, histology_code, behavior, cnt, 
first_value (concept_id) over (partition by  icd_code, histology_code, behavior order by length (concept_name)) as concept_id,
first_value (concept_name) over (partition by  icd_code, histology_code, behavior order by length (concept_name)) as concept_name,
first_value (concept_code) over (partition by  icd_code, histology_code, behavior order by length (concept_name)) as concept_code
 from onc_emr_mapped
where (icd_code, histology_code, behavior) not in (select icd_code, histology_code, behavior from oemr_map_v0)
;
--4. resulting union
 create table oemr_map as
select icd_code,histology_code,behavior,cnt, concept_id,concept_name,concept_code, histology_code || '/' || behavior|| '-' || icd_code as condition_source_value,null as condition_source_concept_id from onc_emr_mapped_dedup
union all
select icd_code,histology_code,behavior,cnt,   concept_id,concept_name,concept_code  , source_value as condition_source_value , source_concept_id as condition_source_concept_id from oemr_map_v0 
;
