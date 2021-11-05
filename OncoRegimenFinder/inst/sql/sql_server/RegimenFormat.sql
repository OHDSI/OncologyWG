IF OBJECT_ID('@writeDatabaseSchema.@regimenIngredientTable', 'U') IS NOT NULL
DROP TABLE @writeDatabaseSchema.@regimenIngredientTable;

with regimens as (
    select distinct r.person_id, r.ingredient_start_date as regimen_start_date, concept_name
    from @writeDatabaseSchema.@regimenTable r
),
CTE as (
	SELECT r.person_id, r.regimen_start_date
		 , STUFF((
		   SELECT ',' + r1.concept_name
			 FROM regimens r1
			WHERE r1.person_id = r.person_id and r1.regimen_start_date=r.regimen_start_date
			ORDER BY r1.concept_name
			  FOR XML PATH('')), 1, LEN(','), '') AS regimen
	FROM regimens r
	GROUP BY r.person_id, r.regimen_start_date
)
select cte.person_id, orig.drug_era_id, i.concept_name as ingredient, i.ingredient_start_date, i.ingredient_end_date,
        cte.regimen, vt.concept_id as hemonc_concept_id, vt.reg_name, cte.regimen_start_date, max(i.ingredient_end_date) over (partition by cte.regimen_start_date, cte.person_id) as regimen_end_date
into @writeDatabaseSchema.@regimenIngredientTable
from @writeDatabaseSchema.@regimenTable orig
left join cte on cte.person_id = orig.person_id and cte.regimen_start_date = orig.ingredient_start_date
left join @writeDatabaseSchema.@cohortTable i on i.person_id = orig.person_id and i.drug_era_id = orig.drug_era_id
left join @writeDatabaseSchema.@vocabularyTable vt on cte.regimen = vt.combo_name
order by cte.person_id, regimen_start_date
