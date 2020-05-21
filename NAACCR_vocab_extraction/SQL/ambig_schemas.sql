create table schema_group as
select 
'bile_ducts_distal' as schema_code, 1 as schema_group_num union 
select'bile_ducts_perihilar', 1 union
select'cystic_duct', 1 union

select'esophagus_gejunction',2  union
select'stomach', 2 union

select'lacrimal_gland', 3 union
select'lacrimal_sac', 3 union

select'melanoma_ciliary_body', 4 union
select'melanoma_iris', 4 union

select'nasopharynx', 5 union
select'pharyngeal_tonsil', 5 union

select'peritoneum', 6 union
select'peritoneum_female_gen', 6
;
--look for each group separately 
select * from (
select item, concept_name, count (1) OVER (partition by item) as cnt
 from (
select distinct regexp_replace (concept_code_2, '.*@', '') as item, concept_name from schema_group z
join concept_relationship_stage on concept_code_1 = schema_code and relationship_id = 'Schema to Variable'
join concept_stage on concept_code_2 = concept_code
 where  schema_group_num = 6 -- here can be other group number
) a ) z where cnt >1
--only schema_group_num = 6 returns ambigous results
;
--Answers, this looks weird
select * from (
select item, value_name, value_code , count (1) OVER (partition by item,value_code) as cnt
 from (
select distinct regexp_replace (r.concept_code_2, '.*@', '') as item,  substring  (r2.concept_code_2 from '\d+$') as value_code, concept_name as value_name from schema_group z
join concept_relationship_stage r on concept_code_1 = schema_code and relationship_id = 'Schema to Variable'
join concept_relationship_stage r2 on r.concept_code_2 = r2.concept_code_1 and r2.relationship_id = 'Has Answer'
join concept_stage on r2.concept_code_2 = concept_code
 where  schema_group_num = 2
) a ) z where cnt >1