with CTE as (
select c1.concept_name as reg_name,
     string_agg(lower(c2.concept_name), ','   order by lower(c2.concept_name) asc) as combo_name,
     c1.concept_id
from @cdmDatabaseSchema.concept_relationship join @cdmDatabaseSchema.concept c1 on c1.concept_id=concept_id_1
join @cdmDatabaseSchema.concept c2 on c2.concept_id=concept_id_2
		where c1.vocabulary_id='HemOnc' and relationship_id='Has antineoplastic'
group by c1.concept_name,c1.concept_id
order by c1.concept_name
),
CTE_second as (
select c.*, (case when lower(reg_name) = regexp_replace(combo_name,',',' and ') then 0
			 else row_number() over (partition by combo_name order by length(c.reg_name)) end ) as rank
from CTE c
order by rank desc
),
CTE_third as (
select *,min(rank) over (partition by combo_name)
from CTE_second
),
CTE_fourth as (
select ct.reg_name, ct.combo_name, ct.concept_id
from CTE_third ct
where rank = min
)

select *
into @writeDatabaseSchema.@vocabularyTable
from CTE_fourth
