with C as (
	select c1.concept_name as reg_name, c2.concept_name, c1.concept_id
	from @vocabDatabaseSchema.concept_relationship
	join @vocabDatabaseSchema.concept c1 on c1.concept_id=concept_id_1
	join @vocabDatabaseSchema.concept c2 on c2.concept_id=concept_id_2
	where c1.vocabulary_id='HemOnc' and relationship_id='Has antineoplastic'
),
CTE as (
	SELECT c0.reg_name
		 , STUFF((
		   SELECT ',' + c1.concept_name
			 FROM C c1
			WHERE c1.reg_name = c0.reg_name
			ORDER BY c1.concept_name
			  FOR XML PATH('')), 1, LEN(','), '') AS combo_name, c0.concept_id
	FROM C c0
	GROUP BY c0.reg_name, c0.concept_id
),
CTE_second as (
select c.*, (case when lower(reg_name) = replace(combo_name,',',' and ') then 0
			 else row_number() over (partition by combo_name order by len(c.reg_name)) end ) as rank
from CTE c
),
CTE_third as (
select z.*, min(rank) over (partition by combo_name) as min
from CTE_second as z
),
CTE_fourth as (
select ct.reg_name, ct.combo_name, ct.concept_id
from CTE_third ct
where rank = min
)
select *
into @writeDatabaseSchema.@vocabularyTable
from CTE_fourth
ORDER BY reg_name