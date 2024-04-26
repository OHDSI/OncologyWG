
drop table if exists @writeDatabaseSchema.@vocabularyTable;

create table @writeDatabaseSchema.@vocabularyTable as
with CTE as (
select c1.concept_name as reg_name,
		 --listagg(lower(c2.concept_name), ',') within group (order by lower(c2.concept_name) asc) as combo_name,
		 group_concat(lower(c2.concept_name), ',') as combo_name,
		 c1.concept_id
from @cdmDatabaseSchema.concept_relationship
join @cdmDatabaseSchema.concept c1 on c1.concept_id=concept_id_1
join @cdmDatabaseSchema.concept c2 on c2.concept_id=concept_id_2
		where c1.vocabulary_id='HemOnc' and relationship_id='Has antineoplastic'
group by c1.concept_name,c1.concept_id
--order by c1.concept_name
order by lower(c2.concept_name) asc
),
CTE_second as (
--select c.*, (case when lower(reg_name) = regexp_replace(combo_name,',',' and ') then 0
select c.*, (case when lower(reg_name) = replace(combo_name,',',' and ') then 0
			 else row_number() over (partition by combo_name order by len(c.reg_name)) end ) as rank
from CTE c
order by rank desc
),
CTE_third as (
select *,min(rank) over (partition by combo_name) as min_combo
from CTE_second
),
CTE_fourth as (
select ct.reg_name, ct.combo_name, ct.concept_id
from CTE_third ct
where rank = min_combo
)
select *
from CTE_fourth
