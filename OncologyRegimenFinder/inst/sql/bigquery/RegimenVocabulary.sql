drop table if exists @writeDatabaseSchema.@vocabularyTable;
create table @writeDatabaseSchema.@vocabularyTable (
  reg_name string,
  combo_name string,
  concept_id bigint
);
INSERT INTO @writeDatabaseSchema.@vocabularyTable(
  reg_name,
  combo_name,
  concept_id
)

with CTE as (
select c1.concept_name as reg_name,
		 STRING_AGG(lower(c2.concept_name), ','
		 order by lower(c2.concept_name)) as combo_name,
		 c1.concept_id
from @cdmDatabaseSchema.concept_relationship
join @cdmDatabaseSchema.concept c1 on c1.concept_id=concept_id_1
join @cdmDatabaseSchema.concept c2 on c2.concept_id=concept_id_2
		where c1.vocabulary_id='HemOnc' and relationship_id IN (
		                            'Has AB-drug cjgt',
                                'Has cytotox chemo',
                                'Has endocrine tx',
                                'Has immunotherapy',
                                'Has pept-drg cjg',
                                'Has radiocjgt',
                                'Has radiotherapy',
                                'Has targeted tx',
                                'Has antineopl',
                                'Has immunosuppr',
                                'Has antineoplastic'
                                )

group by c1.concept_name,c1.concept_id
order by c1.concept_name
),
CTE_second as (
select c.*, (case when lower(reg_name) =
       regexp_replace(combo_name, ',' ,' and ') then 0
			 else row_number() over (partition by combo_name order by c.reg_name) end ) as rank_
from CTE c
order by rank_ desc
),
CTE_third as (
select *, min(rank_) over (partition by combo_name) as rank
from CTE_second
),
CTE_fourth as (
select ct.reg_name, ct.combo_name, ct.concept_id, min(rank) over (partition by combo_name)
from CTE_third ct
)

SELECT reg_name, combo_name, concept_id FROM CTE_fourth
