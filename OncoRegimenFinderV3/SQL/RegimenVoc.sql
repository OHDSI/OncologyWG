with CTE as (
  select c1.concept_name as reg_name, 
		 listagg(lower(c2.concept_name), ',') within group (order by lower(c2.concept_name) asc) as combo_name, 
		 c1.concept_id
from @cdmDatabaseSchema.concept_relationship join concept c1 on c1.concept_id=concept_id_1 
join @cdmDatabaseSchema.concept c2 on c2.concept_id=concept_id_2
		where c1.vocabulary_id='HemOnc' and relationship_id='Has antineoplastic'
group by c1.concept_name,c1.concept_id
order by c1.concept_name
)
select * 
into @writeDatabaseSchema.@vocabularyTable
from CTE