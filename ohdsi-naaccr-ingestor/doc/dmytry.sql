select * from (
select
ICDO_code, naacr_item,  Question_name,schema_id, count (1) over (partition by ICDO_code, naacr_item) as cnt
from (

select distinct a.concept_code_2 as Icdo_code, a.concept_code_1 as schema_id, regexp_replace (ac.concept_code, '.*@', '') as naacr_item,   ac.concept_name as question_name

from concept_relationship_stage a
join concept_relationship_stage x on x.concept_code_1 = a.concept_code_1 and x.relationship_id = 'Schema to Variable'
join concept_stage ac on ac.concept_code = x.concept_code_2 and ac.concept_class_id ='NAACCR Variable'
where a.relationship_id = 'Schema to ICDO'
) a
) z where z.cnt>1
and
(ICDO_code, naacr_item,  Question_name) in (

select ICDO_code, naacr_item,  Question_name from (
select
ICDO_code, naacr_item,  Question_name, count (1) over (partition by ICDO_code, naacr_item) as cnt
from (

select distinct a.concept_code_2 as Icdo_code,  regexp_replace (ac.concept_code, '.*@', '') as naacr_item,   ac.concept_name as question_name

from concept_relationship_stage a
join concept_relationship_stage x on x.concept_code_1 = a.concept_code_1 and x.relationship_id = 'Schema to Variable'
join concept_stage ac on ac.concept_code = x.concept_code_2 and ac.concept_class_id ='NAACCR Variable'
where a.relationship_id = 'Schema to ICDO'
) a
) z where z.cnt>1
)
