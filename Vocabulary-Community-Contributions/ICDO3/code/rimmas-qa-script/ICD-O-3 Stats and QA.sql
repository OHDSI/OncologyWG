with 

-- Overall count of pre-coordinated ICD-O conditions
cond as
(select c.*
from concept c
where c.vocabulary_id = 'ICDO3'
and c.domain_id = 'Condition'
),

-- Count of pre-coordinated ICD-O conditions with topography only
cond_t as
(select c.*
from concept c
where c.vocabulary_id = 'ICDO3'
and c.domain_id = 'Condition'
and c.concept_code like 'NULL%'
),

-- Count of pre-coordinated ICD-O conditions with histology only
cond_h as
(select c.*
from concept c
where c.vocabulary_id = 'ICDO3'
and c.domain_id = 'Condition'
and c.concept_code like '%NULL'
),

-- Concepts by valid status
cond_v as
(select c.invalid_reason, count(*)
from concept c
where c.vocabulary_id = 'ICDO3'
and c.domain_id = 'Condition'
group by c.invalid_reason
),

-- Counts of ICD-O conditions mappings
cond_map as
(select coalesce(c1.standard_concept, 'N') as standard_concept, 
coalesce(cr.relationship_id, 'Not mapped') as 'Maps to', 
c2.vocabulary_id,
count(*)
from concept c1
left join concept_relationship cr 
on c1.concept_id = cr.concept_id_1 and cr.relationship_id = 'Maps to'
left join concept c2 
on cr.concept_id_2 = c2.concept_id
where c1.vocabulary_id = 'ICDO3'
and c1.domain_id = 'Condition'
group by c1.standard_concept, cr.relationship_id, c2.vocabulary_id
),

-- Unmapped ICD-O conditions
cond_nomap as
(select c1.*
from concept c1
left join concept_relationship cr 
on c1.concept_id = cr.concept_id_1 and cr.relationship_id = 'Maps to'
left join concept c2 
on cr.concept_id_2 = c2.concept_id
where c1.vocabulary_id = 'ICDO3'
and c1.domain_id = 'Condition'
and cr.concept_id_1 is NULL
),

-- Completenesss and concordance between ICD-O and SNOMED topography relationships
cond_t_rel as
(select distinct c1.concept_name as icd_o_site, c1.vocabulary_id as voc_1, c2.concept_name as snomed_site, c2.vocabulary_id as voc_2
from concept c0
left join concept_relationship cr1 
on c0.concept_id = cr1.concept_id_1 
and cr1.relationship_id = 'Has Topography ICDO'
left join concept c1 
on cr1.concept_id_2 = c1.concept_id
left join concept_relationship cr2 
on c0.concept_id = cr2.concept_id_1 
and cr2.relationship_id = 'Has finding site'
left join concept c2 
on cr2.concept_id_2 = c2.concept_id
where c0.vocabulary_id = 'ICDO3'
and c0.domain_id = 'Condition'
and c0.invalid_reason is null
and coalesce(c0.standard_concept, 'N') = 'S'
),

-- Completenesss and concordance between ICD-O and SNOMED histology relationships
cond_h_rel as
(select distinct c1.concept_name as icd_o_hist, c1.vocabulary_id as voc_1, c2.concept_name as snomed_morph, c2.vocabulary_id as voc_2
from concept c0
left join concept_relationship cr1 
on c0.concept_id = cr1.concept_id_1 
and cr1.relationship_id = 'Has Histology ICDO'
left join concept c1 
on cr1.concept_id_2 = c1.concept_id
left join concept_relationship cr2 
on c0.concept_id = cr2.concept_id_1 
and cr2.relationship_id = 'Has asso morph'
left join concept c2 
on cr2.concept_id_2 = c2.concept_id
where c0.vocabulary_id = 'ICDO3'
and c0.domain_id = 'Condition'
and c0.invalid_reason is null
and coalesce(c0.standard_concept, 'N') = 'S'
)


-- QUERY
select *
from ...

