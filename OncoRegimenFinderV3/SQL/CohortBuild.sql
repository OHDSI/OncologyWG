DROP TABLE IF EXISTS @writeDatabaseSchema.@cohortTable;
DROP TABLE IF EXISTS @writeDatabaseSchema.@regimenTable;

with CTE_second as (
select 
       lower(c.concept_name) as concept_name,
       de.drug_era_id, 
       de.person_id, 
       de.drug_concept_id, 
       de.drug_era_start_date as ingredient_start_date,
       de.drug_era_end_date as ingredient_end_date
from @cdmDatabaseSchema.drug_era de 
inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = de.drug_concept_id
inner join @cdmDatabaseSchema.concept c on c.concept_id = ca.ancestor_concept_id
    where c.concept_id in (
          select descendant_concept_id as drug_concept_id from @cdmDatabaseSchema.concept_ancestor ca1
          where ancestor_concept_id in (
										SELECT distinct c1.concept_id
										FROM  @cdmDatabaseSchema.concept c1 JOIN @cdmDatabaseSchema.concept_ancestor ca1 ON ca1.descendant_concept_id = c1.concept_id
																			JOIN @cdmDatabaseSchema.concept c2           ON ca1.ancestor_concept_id = c2.concept_id                         
										WHERE c1.concept_class_id = 'Ingredient'
										AND ca1.ancestor_concept_id IN(
											  35807188  --Chemotherapeutic
											, 35807205  --Endocrine therapeutic
											, 35807267  --Enzyme
											, 35807277  --Hypomethylating agent
											, 35807493  --Immunosuppresant
											, 35807335  --Immunosuppressant
											, 35807189  --Immunotherapeutic
										)
										AND EXISTS(
										  SELECT 1
										  FROM @cdmDatabaseSchema.concept_relationship cr1
										  WHERE c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id IN('Rx antineopl of', 'Rx immunosuppr of')
										)
		  ) /* Drug concept_id  */ 
)
and c.concept_class_id = 'Ingredient'
)
select * 
into @writeDatabaseSchema.@cohortTable
from CTE_second;

select * into  @writeDatabaseSchema.@regimenTable
from @writeDatabaseSchema.@cohortTable;
