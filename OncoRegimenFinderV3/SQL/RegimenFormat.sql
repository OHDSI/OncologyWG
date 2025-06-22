drop table if exists  @writeDatabaseSchema.@regimenIngredientTable;

with cte as (
select r.person_id, r.ingredient_start_date as regimen_start_date,
       string_agg(distinct lower(r.concept_name), ','   order by lower(r.concept_name) ) as regimen
from @writeDatabaseSchema.@regimenTable r
group by r.person_id, r.ingredient_start_date
)
select cte.person_id, orig.drug_exposure_id, i.concept_name as ingredient, i.ingredient_start_date, i.ingredient_end_date,
        cte.regimen, vt.concept_id as hemonc_concept_id, vt.reg_name, cte.regimen_start_date, max(i.ingredient_end_date) over (partition by cte.regimen_start_date, cte.person_id) as regimen_end_date
into @writeDatabaseSchema.@regimenIngredientTable
from @writeDatabaseSchema.@regimenTable orig
left join cte on cte.person_id = orig.person_id and cte.regimen_start_date = orig.ingredient_start_date
left join @writeDatabaseSchema.@cohortTable i on i.person_id = orig.person_id and i.drug_exposure_id = orig.drug_exposure_id
left join @writeDatabaseSchema.@vocabularyTable vt on cte.regimen = vt.combo_name
order by cte.person_id, regimen_start_date
