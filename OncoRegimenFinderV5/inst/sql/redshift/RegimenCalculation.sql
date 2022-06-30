DROP TABLE IF EXISTS @writeDatabaseSchema.@regimenTable_tmp;

WITH add_groups AS (
  SELECT r1.person_id, r1.drug_era_id, r1.concept_name, r1.ingredient_start_date, min(r2.ingredient_start_date) as ingredient_start_date_new
  FROM @writeDatabaseSchema.@regimenTable r1
  LEFT JOIN @writeDatabaseSchema.@regimenTable r2 on r1.person_id = r2.person_id and
  r2.ingredient_start_date <= (r1.ingredient_start_date) and r2.ingredient_start_date >= (r1.ingredient_start_date - @dateLagInput)
  GROUP BY r1.person_id, r1.drug_era_id, r1.concept_name, r1.ingredient_start_date
),
regimens AS (
  SELECT person_id, ingredient_start_date_new,
  MAX(CASE WHEN ingredient_start_date = ingredient_start_date_new THEN 1 ELSE 0 END) as contains_original_ingredient
  FROM add_groups g
  GROUP BY ingredient_start_date_new, person_id
  ORDER BY ingredient_start_date_new
),
regimens_to_keep AS (
SELECT rs.person_id, gs.drug_era_id, gs.concept_name, rs.ingredient_start_date_new as ingredient_start_date
FROM regimens rs
LEFT JOIN add_groups gs on rs.person_id = gs.person_id and rs.ingredient_start_date_new = gs.ingredient_start_date_new
WHERE contains_original_ingredient > 0
),
updated_table AS (
SELECT * FROM regimens_to_keep
UNION
SELECT person_id, drug_era_id, concept_name, ingredient_start_date
FROM @writeDatabaseSchema.@regimenTable WHERE drug_era_id NOT IN (SELECT drug_era_id FROM regimens_to_keep)
)
SELECT person_id, drug_era_id, concept_name, ingredient_start_date
INTO @writeDatabaseSchema.@regimenTable_tmp
FROM updated_table;

DROP TABLE IF EXISTS @writeDatabaseSchema.@regimenTable;

CREATE TABLE @writeDatabaseSchema.@regimenTable (
       person_id bigint not null,
       drug_era_id bigint,
       concept_name varchar(max),
       ingredient_start_date date not null
) DISTKEY(person_id) SORTKEY(person_id, ingredient_start_date);

INSERT INTO  @writeDatabaseSchema.@regimenTable (
SELECT * FROM @writeDatabaseSchema.@regimenTable_tmp);

DROP TABLE IF EXISTS @writeDatabaseSchema.@regimenTable_tmp;


