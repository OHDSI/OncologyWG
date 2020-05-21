select distinct 
 b.*, n.unit_concept_Id,c.concept_name, 'Has unit' as relationship_id
  from concept_numeric_stage n
join concept_Stage a using (concept_Code) 
join concept_relationship_Stage on concept_code_2 = a.concept_code and relationship_id ='Has permiss range'
join concept_Stage b on b.concept_Code = concept_Code_1
join concept c on  n.unit_concept_Id = c.concept_id 
where a.concept_class_id ='Permissible Range' and b.concept_class_Id ='NAACCR Variable'
;