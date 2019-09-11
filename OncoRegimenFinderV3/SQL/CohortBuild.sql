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
          where ancestor_concept_id in (@drug_classification_id_input) /* Drug concept_id  */ 
)
and c.concept_class_id = 'Ingredient'
)
select * 
into @writeDatabaseSchema.@cohortTable
from CTE_second;

select * into  @writeDatabaseSchema.@regimenTable 
from @writeDatabaseSchema.@cohortTable;