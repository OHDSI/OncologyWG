DROP TABLE IF EXISTS @writeDatabaseSchema.@cohortTable;
DROP TABLE IF EXISTS @writeDatabaseSchema.@regimenTable;

CREATE TABLE @writeDatabaseSchema.@regimenTable (
       concept_name string,
       drug_era_id bigint,
       person_id bigint not null,
       rn bigint,
       drug_concept_id bigint,
       ingredient_start_date date not null,
       ingredient_end_date date
);

CREATE TABLE @writeDatabaseSchema.@cohortTable (
       concept_name string,
       drug_era_id bigint,
       person_id bigint not null,
       rn bigint,
       drug_concept_id bigint,
       ingredient_start_date date not null,
       ingredient_end_date date
);


insert into @writeDatabaseSchema.@cohortTable
(with CTE_second as (
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
          @drugClassificationIdInput
  ) )
and c.concept_class_id = 'Ingredient'
)
select cs.concept_name,
       cs.drug_era_id,
       cs.person_id ,
       c2.rn,
       cs.drug_concept_id,
       cs.ingredient_start_date,
       cs.ingredient_end_date
from CTE_second cs
inner join (select distinct person_id,
row_number()over(order by person_id) rn
from (SELECT distinct person_id FROM
CTE_second) cs) c2 on c2.person_id = cs.person_id
);


insert into  @writeDatabaseSchema.@regimenTable
(select *
from @writeDatabaseSchema.@cohortTable);
