with CTE as (
select c.person_id,
	   min(c.condition_start_date) as start_date
from @cdmDatabaseSchema.condition_occurrence c
where condition_concept_id in (
	select descendant_concept_id as condition_concept_id from @cdmDatabaseSchema.concept_ancestor ca1
	where ancestor_concept_id in (@condition_id_input) /* Cancer concept_id */ 
)
group by c.person_id, c.condition_concept_id
),
CTE_second as (
select 
	   ct.start_date,
	   c.concept_name,
	   de.drug_exposure_id, 
	   de.person_id, 
	   de.drug_concept_id, 
	   de.drug_exposure_start_date, 
	   de.drug_type_concept_id, 
	   de.days_supply, 
	   de.route_concept_id, 
	   de.visit_occurrence_id, 
	   de.drug_source_value, 
	   de.drug_source_concept_id, 
	   de.route_source_value, 
	   de.dose_unit_source_value
from CTE ct
inner join @cdmDatabaseSchema.drug_exposure de on de.person_id = ct.person_id
inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = de.drug_concept_id
inner join @cdmDatabaseSchema.concept c on c.concept_id = ca.ancestor_concept_id
  where de.drug_exposure_start_date >= ct.start_date - 30
	and c.concept_id in (
		  select descendant_concept_id as drug_concept_id from @cdmDatabaseSchema.concept_ancestor ca1
		  where ancestor_concept_id in (@drug_classification_id_input) /* Drug concept_id  */ 
)
and c.concept_class_id = 'Ingredient'
)
select lower(concept_name) as concept_name, person_id, drug_exposure_start_date as ingredient_start_date, days_supply, start_date
into #rawevents
from CTE_second
