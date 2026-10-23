create table if not exists static.invalid_grade (
  concept_id int
);

create table if not exists static.invalid_stage (
  concept_id int
);

create table if not exists static.invalid_met (
  concept_id int
);

create table if not exists static.correct_grade (
  concept_id int
);

create table if not exists static.correct_stage (
  concept_id int
);

create table if not exists static.correct_met (
  concept_id int
);

create table if not exists static.all_grade (
  concept_id int
);

create table if not exists static.all_stage (
  concept_id int
);

create table if not exists static.all_met (
  concept_id int
);

delete from static.correct_met;
insert into static.correct_met
select concept_id
from devv5_202608.concept 
where vocabulary_id='Cancer Modifier' 
and concept_class_id='Metastasis'
and standard_concept='S';

delete from static.correct_stage;
insert into static.correct_stage
select concept_id
from devv5_202608.concept 
where vocabulary_id='Cancer Modifier'
and concept_class_id='Staging/Grading'
and standard_concept='S'
and (
  concept_name ilike '%stage%'
  or concept_name like 'AJCC%'
  or concept_name like 'Intergroup Rhabdomyosarcoma%'
  or concept_name like 'Anatomic Clark%'
  or concept_name like 'Reese_Ellsworth%'
)
and concept_name not ilike '%grade%';

delete from static.correct_grade;
insert into static.correct_grade
select concept_id
from devv5_202608.concept
where vocabulary_id='Cancer Modifier' 
and concept_class_id='Staging/Grading'
and standard_concept='S'
and (
  concept_name ilike '%grade%'
  or concept_name like 'Nottingham%'
  or concept_name like '%Gleason%'
);

delete from static.invalid_met;
insert into static.invalid_met
select concept_id_1 as concept_id
from devv5_202608.concept_relationship
join static.correct_met on concept_id = concept_id_2
where relationship_id = 'Maps to'
and concept_id_1 <> concept_id_2;

delete from static.invalid_stage;
insert into static.invalid_stage
select concept_id_1 as concept_id
from devv5_202608.concept_relationship
join static.correct_stage on concept_id = concept_id_2
where relationship_id = 'Maps to'
and concept_id_1 <> concept_id_2;

delete from static.invalid_grade;
insert into static.invalid_grade
select concept_id_1 as concept_id
from devv5_202608.concept_relationship
join static.correct_grade on concept_id = concept_id_2
where relationship_id = 'Maps to'
and concept_id_1 <> concept_id_2;


delete from static.all_grade;
insert into static.all_grade
select concept_id from static.invalid_grade
union
select concept_id from static.correct_grade;

delete from static.all_stage;
insert into static.all_stage
select concept_id from static.invalid_stage
union
select concept_id from static.correct_stage;

delete from static.all_met;
insert into static.all_met
select concept_id from static.invalid_met
union
select concept_id from static.correct_met;
