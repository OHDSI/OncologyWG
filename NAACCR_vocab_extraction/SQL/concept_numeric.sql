create table concept_as_range  
as
select 
a.concept_code , a.concept_name, b.concept_code as question_code, b.concept_name as question_name
 from concept_stage a
join concept_relationship_stage on relationship_id ='Has Answer' and concept_code_2 = concept_code
join concept_Stage b on concept_code_1 = b.concept_Code
where a.concept_class_id = 'NAACCR Value'
and a.concept_name ~* '(less than|at least|more|greater|equal).*\d|Stated as (a range )?\d|\d cm to \d+ cm|ng/mL|mIU/mL|U/L|U/ml|\(mm\)|points\)|\d.*or (larger|greater|more|less)|Range of values is'
and b.concept_name ~* 'count|Size|Value|Distance|Measured|Rate|Sarcomatoid Features|Oncotype Dx Recurrence Score-Invasive|Thickness|Margin|Copy Number|Normalized Ratio|Number of|Range|Weight|Tumor Deposits|Labeling Index|Prognostic Index'