--tables taken from SEER API
/*
api_algorithm_schema -- in the future replace them with only the latest version
api_algorithm_table -- in the future replace them with only the latest version
naaccr_list
item_1c
proc_naaccr
histology_site
*/

/* -- in the future upload only the latest version, so don't need this
create table algorithm_schema_latest as
select * from api_algorithm_schema where (algorithm, version) in (
select algorithm, max (version) from api_algorithm_schema group by algorithm
)
;
create table algorithm_table_latest as
select * from api_algorithm_table where (algorithm, version) in ( 
select algorithm, max (version) from api_algorithm_table group by algorithm
)
;
*/

/*
--preleminary steps:
--0.1. Need to connect schema_id, naaccr_item , value_code. So creating schema_table
 create table schema_table  as
 select  distinct s.algorithm,  s.schema_id, s.schema_description, s.naaccr_item, s.table_id,  s.table_name as schema_table_name, 
 t.table_name as table_table_name, t.table_title, t.value_code,t. value_description
  from algorithm_schema_latest s
 join algorithm_table_latest t 
 --these can by used as a foreign keys
using (algorithm, version, table_id)
;
--0.2 Define Site-specific list of concepts
--actually there are two groups of schema_specific questions
--where name ~ 'Site-Specific|Schema Discriminator' these will have both site-specific Questions and site-specific Answers
--where name !~ 'Site-Specific|Schema Discriminator' these will have only site-specific Answers 
drop table schema_specific_list ;
create table schema_specific_list as 
select item from naaccr_list where name like '%Site-Specific%' or item in (
'2810',
'2830',
'2840',
'2850',
'2860',
'2800',
'764',
'776',
'772',
'774',
'3843',
'3844',
'3845',
'2820',
'3926' ,-- Schema Discriminator 1
'3927' -- Schema Discriminator 2
)
;
--0.3 Define site non-specific
drop table site_non_specific;
create table site_non_specific as
select distinct  
naaccr_item,
first_value (table_title ) over  (partition by naaccr_item order by table_title_cnt desc, table_title) as table_title
, value_code , 
first_value (value_description) over (partition by naaccr_item, value_code order by value_description_cnt desc, value_description ) as value_description
 from (
 select  
 naaccr_item,
table_title, count (1) over (partition by naaccr_item, table_title) as table_title_cnt,
trim (value_code) as value_code,
 value_description, count (1) over (partition by naaccr_item, trim (value_code)) as value_description_cnt
  from schema_table 
 where naaccr_item not in (select * from schema_specific_list) 
  and naaccr_item not in ('522', -- Histology
  '400', --Site
  '390',  --CS Year Validation
  '230' ) -- new added by Denys to exclude incorrect values for 'Age at diagnosis' they will be added with table item_1c
  ) a
 ;
 
--0.4 site_specific variables and values
drop table site_specific;
create table site_specific as
select * from (
select distinct schema_id,
naaccr_item ,
case when naaccr_item in ('3926', '3927', '3700') --  Schema Discriminator 1 and 2 
then first_value( table_title)  over (partition by schema_id,naaccr_item order by algorithm, table_title) 
else 
first_value( schema_table_name)  over (partition by schema_id,naaccr_item order by algorithm, schema_table_name) end
as schema_table_name,
trim (value_code) as value_code,
first_value ( value_description) over (partition by schema_id,naaccr_item,  trim (value_code) order by algorithm, value_description) as value_description 
 from schema_table 
 where naaccr_item  in (select * from schema_specific_list)
 and naaccr_item not in ('522', -- Histology
  '400', --Site
  '390') --CS Year Validation
  ) r 
  where schema_table_name !~ 'Site-Specific'
;
*/


-- 0. Update latest_update field to new date 
DO $_$
BEGIN
	PERFORM VOCABULARY_PACK.SetLatestUpdate(
	pVocabularyName			=> 'NAACCR',
	pVocabularyDate			=> to_date ('2018-03-02', 'yyyy-mm-dd'), -- https://www.naaccr.org/data-standards-data-dictionary/#DataDictionary -- Version 18 Data Standards and Data Dictionary – (posted 3/2/18;
	pVocabularyVersion		=> 'NAACCR v18',
	pVocabularyDevSchema	=> 'DEV_naaccr'
);
END $_$;

--_stage tables work
truncate table concept_stage
;
--1. schema concepts
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
--take the longest (most explicit description)
select distinct 
null::int, 
first_value (schema_description) over (partition by  schema_id order by length (schema_description) desc) as concept_name ,
'Observation',
'NAACCR',
'NAACCR Schema',
null,
schema_id ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from algorithm_schema_latest 
;

--2.1. site specific Questions 
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
schema_table_name, -- removed schema_id from here
'Measurement',
'NAACCR',
'NAACCR Variable',
null,
schema_id|| '@' ||naaccr_item ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from site_specific join naaccr_list 
on naaccr_item =item 
--just that, only these two types of questions have different meaning over schemas 
where name ~ 'Site-Specific|Schema Discriminator' 
;

--2.2 site non specific Question
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
name, 
'Measurement', 
'NAACCR',
'NAACCR Variable',
null,
item ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from naaccr_list where name !~ 'Site-Specific|Schema Discriminator'
-- add missing variables from https://github.com/OHDSI/OncologyWG/issues/151
union 
select 
distinct 
null::int, 
item_name, 
case when item_number in ('420','430','523','3928') then 'Observation' else  'Measurement' end, 
'NAACCR',
'NAACCR Variable',
null,
item_number ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from naaccr_items
where item_number not in (select item from naaccr_list)
and item_number not in ('522')
or item_number in ('3928')
;

--3.1. Values non-specific
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
substr (regexp_replace (regexp_replace (   value_description , '[[:cntrl:]]', '|', 'g'), ' +', ' ', 'g'), 0, 255) as concept_name, --replace "new_line" with "|", remove multiple spaces, cut to 255 symbols
'Meas Value',
'NAACCR',
'NAACCR Value',
null,
naaccr_item|| '@' ||value_code ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from site_non_specific 
where  value_description is not null -- NULL value_description is in Age at Diagnosis ,  CS Version Input Original -- don't need these values anyway
;

--3.2. values of site specific
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
substr (regexp_replace (regexp_replace (   (value_description) , '[[:cntrl:]]', '|', 'g'), ' +', ' ', 'g'), 0, 255) as concept_name, --removing new_line characters, multiple spaces, cut to 255 symbols
'Meas Value',
'NAACCR',
'NAACCR Value',
null,
schema_id ||'@'|| naaccr_item ||'@' || value_code ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from site_specific
;
--3.3. values that don't exist in staging algorythm tables
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select 
distinct 
null::int, 
substr (regexp_replace (regexp_replace (   (description) , '[[:cntrl:]]', '|', 'g'), ' +', ' ', 'g'), 0, 255) as concept_name,
'Meas Value',
'NAACCR',
'NAACCR Value',
null,
a.item ||'@' || code ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
 from naaccr_list a 
 join item_1c c on c.item = a.item -- item_1c table taken from SEER API
 where a.item not in (
( select naaccr_item from site_specific union select naaccr_item   from site_non_specific)
 )
 and c.description is not null and code !='Blank'
and a.item not in (select item from naaccr_value_edit)
and a.item not in ('2190')
--add missing values from https://github.com/OHDSI/OncologyWG/issues/81 and https://github.com/OHDSI/OncologyWG/issues/94 and https://github.com/OHDSI/OncologyWG/issues/78
union
select 
distinct 
null::int, 
substr (description, 0, 255) as concept_name,
'Meas Value',
'NAACCR',
'NAACCR Value',
null,
a.item ||'@' || code ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
 from naaccr_list a 
 join naaccr_value_edit c on c.item = a.item
 where c.item not in ('380','560')
;

--4. procedures
--4.1.NAACCR Proc Schema
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
title as concept_name ,
'Observation',
'NAACCR',
'NAACCR Proc Schema',
null,
title ,  
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from proc_naaccr 
;
--4.2. insert procedure concepts 
insert into concept_stage (concept_id,concept_name,domain_id,vocabulary_id,concept_class_id,standard_concept,concept_code,valid_start_date,valid_end_date,invalid_reason)
select distinct 
null::int, 
substr ( title ||'@'||description , 0, 255) as concept_name , -- in this case name has schema in it, for example Pharynx@Cryosurgery
'Procedure',
'NAACCR',
'NAACCR Procedure',
null,
title ||'@1290@'||  code,  --'1290' = 'RX Summ--Surg Prim Site'
to_date ('19700101', 'yyyymmdd'),
to_date ('20991231', 'yyyymmdd'),
null
from proc_naaccr 
;
--ICD10 codes are already encoded in OHDSI vocabulary, so we remove all answers with them, here's an example of such concept   3798@T36.0 - T50.996
delete from concept_stage where concept_class_id = 'NAACCR Value' and concept_code ~ '\D\d\d\.\d - \D\d\d\.\d'
;
--these are groups of Procedure concepts, don't exist in a registry
delete from concept_stage where concept_code ~ '20-80|10-20|19-Oct'
;
INSERT INTO concept_stage
(
  concept_id,
  concept_name,
  domain_id,
  vocabulary_id,
  concept_class_id,
  standard_concept,
  concept_code,
  valid_start_date,
  valid_end_date,
  invalid_reason
)
VALUES
(
  NULL,
  'Histology',
  'Measurement',
  'NAACCR',
  'NAACCR Variable',
  'S',
  '522',
  DATE '1970-01-01',
  DATE '2099-12-31',
  NULL
)
;
--manual ingestion clean up
UPDATE concept_stage
   SET concept_code = '835@01-90'
WHERE concept_code = '835@Jan-90';
UPDATE concept_stage
   SET concept_code = '834@01-90'
WHERE concept_code = '834@Jan-90';
--manual ingestion clean up
update concept_stage set concept_name = replace (concept_name, '"', '') where concept_name like '"%"' 
;
--trailing zeroes
--https://github.com/OHDSI/OncologyWG/issues/60
update concept_stage set concept_code = regexp_replace (concept_code,'@.*', '') ||'@0' || regexp_replace (concept_code, '.*@', '') where concept_code ~ '(1390|1400|1410|1506|1516|1526)@.*' and length (concept_code ) =6
;
update concept_stage set concept_code =  concept_code ||'0'  where concept_code ~ '.*1290@0' ;
;
--check for duplicates
select concept_code from concept_stage
group by concept_code having count(1) >1
--done
;
with r as (
SELECT *,
       CASE
         WHEN concept_code ~ '\@\d$' THEN SUBSTRING(concept_code,'(\d+\@)') || '0' ||substring (concept_code,'\@(\d)$')
         ELSE concept_code
       END AS new_code
FROM concept_stage
WHERE concept_code LIKE '160@%'
)

update concept_stage a
set concept_code = new_code
from r 
where a.concept_code = r.concept_code


;
--5. relationships
truncate table concept_relationship_stage
;
--5.1 Has Answer
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, a.concept_code, b.concept_code, 'NAACCR', 'NAACCR', 'Has Answer', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage a 
join concept_stage b on (b.concept_code like a.concept_code ||'@%' or b.concept_code like '%@'|| a.concept_code ||'@%')
where a.concept_class_id = 'NAACCR Variable' and b.concept_class_id in ('NAACCR Value' , 'NAACCR Procedure')
;
--5.1.1 Has Answer -- decision for 670 as 670 has the same variables = Procedure codes, I don't want to create new concepts for this, just reuse those for 1290
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, '670', b.concept_code, 'NAACCR', 'NAACCR', 'Has Answer', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage a 
join concept_relationship_stage r  on a.concept_code = r.concept_code_1 
join concept_stage b on b.concept_code = r.concept_code_2
where a.concept_code like '1290%' and b.concept_class_id ='NAACCR Procedure'
;
--5.2 Schema has Variable
--site specific schemas
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, b.concept_code, a.concept_code, 'NAACCR', 'NAACCR', 'Variable to Schema', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage a 
join concept_stage b on b.concept_code like a.concept_code ||'@%'
where a.concept_class_id = 'NAACCR Schema' and b.concept_class_id = 'NAACCR Variable' 
;
--site NON-specific schemas, but in SEER API there is a list of schemas allowed
--select 
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, a.concept_code, b.concept_code, 'NAACCR', 'NAACCR', 'Variable to Schema', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage a 
 join schema_table on concept_code = naaccr_item 
 join concept_stage b on schema_id = b.concept_code and b.concept_class_id ='NAACCR Schema'
where  a.concept_class_id = 'NAACCR Variable'
and a.concept_code not like '%@%'
;
--site NON-specific schemas, but in SEER API there is NO list of schemas allowed
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, a.concept_code, b.concept_code, 'NAACCR', 'NAACCR', 'Variable to Schema', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage a 
 join concept_stage b on b.concept_class_id ='NAACCR Schema'
left join schema_table s on a.concept_code = naaccr_item 
where  a.concept_class_id = 'NAACCR Variable' and s.naaccr_item is null
and a.concept_code not like '%@%'
;
--5.3 Schema has Value
--relationships between NAACCR Schema and Values
--relationships between Procedure Schema and Procedure
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, a.concept_code , b.concept_code  ,'NAACCR', 'NAACCR', 'Schema to Value', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
 from concept_stage a
join concept_stage b on  b.concept_code like a.concept_code ||'@%'||'@%'
where (a.concept_class_id = 'NAACCR Schema' and b.concept_class_id = 'NAACCR Value' or  a.concept_class_id = 'NAACCR Proc Schema' and b.concept_class_id = 'NAACCR Procedure')
;
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct  null::int, null::int, r1.concept_code_2, cs2.concept_code,  'NAACCR', 'NAACCR', 'Schema to Value', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
from concept_stage cs1 
join concept_relationship_stage r1 on r1.concept_code_1 = cs1.concept_code and cs1.concept_class_id = 'NAACCR Variable' and r1.relationship_id = 'Variable to Schema'
join concept_relationship_stage r2 on r1.concept_code_1 = r2.concept_code_1 and r2.relationship_id = 'Has Answer'
join concept_stage cs2 on r2.concept_code_2 = cs2.concept_code  
where cs2.concept_code not in (
select concept_code_2  from concept_relationship_stage 
where relationship_id = 'Schema to Value' 
)
and cs2.concept_class_id = 'NAACCR Value' 
;
 

-- 5.4. build the relations from schema to ICDO condition taken from histology_site table (SEER API)
 -------------------------------------------------------------------------------
drop table if exists schema_to_combo_concept_cs_1;
create table schema_to_combo_concept_cs_1 as
--Execution time: 1m 37s
select  distinct schema_id, f.*
  from 
(
select distinct schema_id,from_site_code, to_site_code,
 substring ( trim (regexp_split_to_table (histology, ',')), '^\d\d\d\d') as from_hist_code,
substring ( trim (regexp_split_to_table (histology, ',')), '\d\d\d\d$') as to_hist_code
  from (
select schema_id, substring ( trim (regexp_split_to_table (site, ',')), '^C(\d\d\d)') as from_site_code,
substring ( trim (regexp_split_to_table (site, ',')), 'C(\d\d\d)$') as to_site_code , histology from 
histology_site
where algorithm ='cs' 
) a 
) a
join concept c on replace(replace ( c.concept_code, '.',''),'C','')::int >= from_site_code::int and replace(replace ( c.concept_code, '.',''),'C','')::int <= to_site_code::int
and c.vocabulary_id ='ICDO3' and c.concept_class_id = 'ICDO Topography'
join concept d on regexp_replace ( d.concept_code, '\/\d$','')::int >= from_hist_code::int and regexp_replace ( d.concept_code, '\/\d$','')::int <= to_hist_code::int
and d.vocabulary_id ='ICDO3' and d.concept_class_id = 'ICDO Histology' and d.invalid_reason is null
join concept_relationship cr on cr.concept_id_1= c.concept_id and cr.relationship_id = 'Topography of ICDO'
join concept_relationship dr on dr.concept_id_1= d.concept_id and dr.relationship_id = 'Histology of ICDO' and cr.concept_id_2 = dr.concept_id_2
join concept f on f.concept_id = dr.concept_id_2 
where f.vocabulary_id ='ICDO3'
;


drop table if exists schema_to_combo_concept_tnm_1;
create table schema_to_combo_concept_tnm_1 as
--Execution time: 1m 37s
select  distinct schema_id, f.*
  from 
(
select distinct schema_id,from_site_code, to_site_code,
 substring ( trim (regexp_split_to_table (histology, ',')), '^\d\d\d\d') as from_hist_code,
substring ( trim (regexp_split_to_table (histology, ',')), '\d\d\d\d$') as to_hist_code
  from (
select schema_id, substring ( trim (regexp_split_to_table (site, ',')), '^C(\d\d\d)') as from_site_code,
substring ( trim (regexp_split_to_table (site, ',')), 'C(\d\d\d)$') as to_site_code , histology from 
histology_site
where algorithm ='tnm' 
) a 
) a
join concept c on replace(replace ( c.concept_code, '.',''),'C','')::int >= from_site_code::int and replace(replace ( c.concept_code, '.',''),'C','')::int <= to_site_code::int
and c.vocabulary_id ='ICDO3' and c.concept_class_id = 'ICDO Topography'
join concept d on regexp_replace ( d.concept_code, '\/\d$','')::int >= from_hist_code::int and regexp_replace ( d.concept_code, '\/\d$','')::int <= to_hist_code::int
and d.vocabulary_id ='ICDO3' and d.concept_class_id = 'ICDO Histology' and d.invalid_reason is null
join concept_relationship cr on cr.concept_id_1= c.concept_id and cr.relationship_id = 'Topography of ICDO'
join concept_relationship dr on dr.concept_id_1= d.concept_id and dr.relationship_id = 'Histology of ICDO' and cr.concept_id_2 = dr.concept_id_2
join concept f on f.concept_id = dr.concept_id_2 
where f.vocabulary_id ='ICDO3'
;



drop table if exists schema_to_combo_concept_eod_1;
create table schema_to_combo_concept_eod_1 as
--Execution time: 1m 37s
select  distinct schema_id, f.*
  from 
(
select distinct schema_id,from_site_code, to_site_code,
 substring ( trim (regexp_split_to_table (histology, ',')), '^\d\d\d\d') as from_hist_code,
substring ( trim (regexp_split_to_table (histology, ',')), '\d\d\d\d$') as to_hist_code
  from (
select schema_id, substring ( trim (regexp_split_to_table (site, ',')), '^C(\d\d\d)') as from_site_code,
substring ( trim (regexp_split_to_table (site, ',')), 'C(\d\d\d)$') as to_site_code , histology from 
histology_site
where algorithm ='eod_public' 
) a 
) a
join concept c on replace(replace ( c.concept_code, '.',''),'C','')::int >= from_site_code::int and replace(replace ( c.concept_code, '.',''),'C','')::int <= to_site_code::int
and c.vocabulary_id ='ICDO3' and c.concept_class_id = 'ICDO Topography'
join concept d on regexp_replace ( d.concept_code, '\/\d$','')::int >= from_hist_code::int and regexp_replace ( d.concept_code, '\/\d$','')::int <= to_hist_code::int
and d.vocabulary_id ='ICDO3' and d.concept_class_id = 'ICDO Histology' and d.invalid_reason is null
join concept_relationship cr on cr.concept_id_1= c.concept_id and cr.relationship_id = 'Topography of ICDO'
join concept_relationship dr on dr.concept_id_1= d.concept_id and dr.relationship_id = 'Histology of ICDO' and cr.concept_id_2 = dr.concept_id_2
join concept f on f.concept_id = dr.concept_id_2 
where f.vocabulary_id ='ICDO3'
;



drop table if exists schema_to_combo_concept_1;
create table schema_to_combo_concept_1 as 
select * from schema_to_combo_concept_cs_1
union
select * from schema_to_combo_concept_eod_1
where concept_id not in (select concept_id from schema_to_combo_concept_cs_1)
union 
select * from  schema_to_combo_concept_tnm_1
where concept_id not in (select concept_id from schema_to_combo_concept_cs_1 union select concept_Id from schema_to_combo_concept_eod_1)
;

--check whether there are duplicates
select * from schema_to_combo_concept_1 where concept_id in (
select concept_id from (
select distinct concept_id, schema_id from schema_to_combo_concept_1 
) a 
group by concept_id having count(1) >1
)
order by concept_code
;--1482



--insert relationship between  NULL-CXX.X and schema 
insert into schema_to_combo_concept_1
with hist as (
select distinct schema_id,from_site_code, to_site_code,
 substring ( trim (regexp_split_to_table (histology, ',')), '^\d\d\d\d') as from_hist_code,
substring ( trim (regexp_split_to_table (histology, ',')), '\d\d\d\d$') as to_hist_code
  from (
select distinct schema_id, substring ( trim (regexp_split_to_table (site, ',')), '^C\d\d\d') as from_site_code,
substring ( trim (regexp_split_to_table (site, ',')), 'C\d\d\d$') as to_site_code , histology from 
histology_site 
) a ),

sch_1 as (
SELECT DISTINCT hist.schema_id,
       c.*
FROM hist 
  JOIN concept c
    ON SUBSTRING (REPLACE (c.concept_code,'.',''),'C\d\d\d$') BETWEEN from_site_code AND to_site_code
   AND c.vocabulary_id = 'ICDO3'
   AND c.concept_code LIKE 'NULL%'

WHERE concept_name ilike '%'||schema_id||'%'
),

sch_2 as (
SELECT DISTINCT schema_id,
       c.*
FROM hist
  JOIN concept c
    ON SUBSTRING (REPLACE (c.concept_code,'.',''),'C\d\d\d$') BETWEEN from_site_code
   AND to_site_code
   AND c.vocabulary_id = 'ICDO3'
   AND c.concept_code LIKE 'NULL%'
   where schema_id NOT IN ('heme_retic','ill_defined_other','kaposi_sarcoma')
AND   schema_id NOT LIKE 'melanoma%'
AND   schema_id NOT LIKE 'myeloma%'
AND   schema_id NOT LIKE '%lymphoma%'
AND   schema_id NOT LIKE 'mycosis%'
AND   schema_id NOT LIKE 'merkel%'
and schema_id NOT LIKE 'net_%'
and schema_id NOT LIKE 'gist_%'
and schema_id NOT LIKE '%junction%'
and schema_id NOT LIKE '%sarcoma'
and schema_id NOT LIKE '%carcinoma'
and schema_id NOT LIKE '%stoma'
and concept_id not in ( select concept_id from sch_1)
),

sch_3 as (
SELECT DISTINCT hist.schema_id,
       c.*
FROM hist
  JOIN concept c
    ON SUBSTRING (REPLACE (c.concept_code,'.',''),'C\d\d\d$') BETWEEN from_site_code
   AND to_site_code
   AND c.vocabulary_id = 'ICDO3'
   AND c.concept_code LIKE 'NULL%'
join schema_to_combo_concept_1 r on substring(r.concept_code, '\-(C\d\d\.\d)$') BETWEEN from_site_code AND to_site_code
where hist.schema_id = r.schema_id
and r.concept_code like '8000/1%'
and c.concept_id not in ( select concept_id from sch_1 union select concept_id from sch_2)
)

SELECT DISTINCT hist.schema_id,
       c.*
FROM hist
  JOIN concept c
    ON SUBSTRING (REPLACE (c.concept_code,'.',''),'C\d\d\d$') BETWEEN from_site_code
   AND to_site_code
   AND c.vocabulary_id = 'ICDO3'
   AND c.concept_code LIKE 'NULL%'
   where c.concept_id not in ( select concept_id from sch_1 union select concept_id from sch_2 union select concept_id from sch_3)
and schema_id in ( select  schema_id from sch_3)
union
select  * from sch_1
union
select  * from sch_2
union
select  * from sch_3
;




--5.4.1 staging schema to ICDO combo
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, schema_id , concept_code  ,'NAACCR', 'ICDO3', 'Schema to ICDO', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
 from schema_to_combo_concept_1
;
--5.5 build the relations from schema to ICDO condition taken from proc_naaccr table (SEER API)
/* -- commented out as it took  12h 37m 48s to create this -- need to rewrite it as: get all combos based on site only and then exctract the exclusions
drop table proc_schema_to_combo_concept
;
--what's called inclusion is an exclusion really
create table proc_schema_to_combo_concept as
--Execution time: 36.07s
select  distinct title, f.*
  from 
(
select distinct title,from_site_code, to_site_code,
 substring ( trim (regexp_split_to_table (hist_inclusions, ',')), '^\d\d\d\d') as from_hist_code,
substring ( trim (regexp_split_to_table (hist_inclusions, ',')), '\d\d\d\d$') as to_hist_code
  from (
select title, substring ( trim (regexp_split_to_table (site_inclusions, ',')), '^C\d\d\d') as from_site_code,
substring ( trim (regexp_split_to_table (site_inclusions, ',')), 'C\d\d\d$') as to_site_code , hist_inclusions from 
proc_naaccr
) a 
) a
join concept c on replace ( c.concept_code, '.','') between from_site_code and to_site_code
join concept d on replace ( d.concept_code, '/%','') between from_hist_code and to_hist_code
join concept_relationship cr on cr.concept_id_1= c.concept_id and cr.relationship_id = 'Topography of ICDO'
left join concept_relationship dr on dr.concept_id_1= d.concept_id and dr.  relationship_id = 'Histology of ICDO' and cr.concept_id_2 = dr.concept_id_2
join concept f on f.concept_id = cr.concept_id_2 and f.vocabulary_id ='ICDO3'
where c.vocabulary_id ='ICDO3' and c.concept_class_id = 'ICDO Topography'
and d.vocabulary_id ='ICDO3' and d.concept_class_id = 'ICDO Histology'
and dr.concept_id_1 is null
;
*/

delete from concept_relationship_stage 
where concept_code_1 in ('brain', 'cns_other')  
and concept_code_2 like '9737/3%';

--5.5.1 procedure schema to ICDO combo
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, title , concept_code  ,'NAACCR', 'ICDO3', 'Proc Schema to ICDO', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null
 from proc_schema_to_combo_concept
 ;

--assign domains based on NAACCR curated
update concept_stage a set domain_id =
(select distinct item_omop_domain_id from naaccr_curated b 
where a.concept_code = b.item_omop_concept_code )
where a.concept_class_id = 'NAACCR Variable'
and exists (
select 1 from naaccr_curated b 
where a.concept_code = b.item_omop_concept_code)
;
--assign standard concepts based on NAACCR curated
update concept_stage a set standard_concept =
(select distinct item_standard_concept from naaccr_curated b 
where a.concept_code = b.item_omop_concept_code )
where a.concept_class_id = 'NAACCR Variable'
and exists (
select 1 from naaccr_curated b 
where a.concept_code = b.item_omop_concept_code)
;
--Values domain are based on their variables
update concept_stage a set domain_id = 'Drug' 
where concept_code ~ '1390|1400|1410' and concept_class_id = 'NAACCR Value'
;
--Values domain are based on their variables
update concept_stage a set domain_id = 'Procedure' 
where concept_code ~ '1290|1506|1516|1526|3250' and concept_class_id in ( 'NAACCR Value')
;
--Values standard_concepts are based on their Flavours of null
update concept_stage a set standard_concept = 'S' 
 where concept_class_id ='NAACCR Value' and domain_id ='Meas Value'
and not concept_name ~ -- not a flavour of null
'^Not documented in medical record|^Not applicable:|^Not documented in patient record|^Not applicable$|^Test ordered, results not in chart|^OBSOLETE DATA|^Unknown|^Not assessed;'
;

--https://github.com/OHDSI/OncologyWG/issues/151
update  concept_stage 
set standard_concept = 'S'
where standard_concept is null and concept_code in ('3700','400', '780', '790', '800', '810', '820', '830','230','676');

update concept_stage 
set standard_concept = 'S'
where concept_code like '%3700';


--https://github.com/OHDSI/OncologyWG/issues/85
update concept_stage 
set standard_concept = 'S'
where concept_code in ('Ovary@1290@26','Ovary@1290@35','Ovary@1290@50','Ovary@1290@55');

--https://github.com/OHDSI/OncologyWG/issues/81
update concept_stage 
set standard_concept = null,
domain_id = 'Observation'
where concept_code in ('2935', '2936', '2937','500');





--build the relationships based on the NAACCR curated
--Variable has date
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, item_omop_concept_code , regexp_replace (item_number_date, ',.*', '')  ,'NAACCR', 'NAACCR', 'Has start date', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'), null
 from naaccr_curated
 join concept_stage on item_omop_concept_code = concept_code and concept_class_id ='NAACCR Variable'
where item_number_date is not null 
union 
 select distinct null::int, null::int, item_omop_concept_code , regexp_replace (item_number_date, '.*,', '')  ,'NAACCR', 'NAACCR', 'Has start date', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'), null
 from naaccr_curated
  join concept_stage on item_omop_concept_code = concept_code and concept_class_id ='NAACCR Variable'
 where item_number_date is not null
 ;
 
update concept_relationship_stage
set relationship_id = 'Has end date'
where concept_code_2 = '3220';





 --build the relationships based on the NAACCR curated
--Has parent item
 insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, item_omop_concept_code , regexp_replace (iten_number_parent, ',.*', '')  ,'NAACCR', 'NAACCR', 'Has parent item', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'), null
 from naaccr_curated
  join concept_stage on item_omop_concept_code = concept_code and concept_class_id ='NAACCR Variable'
where iten_number_parent is not null 
union 
 select distinct null::int, null::int, item_omop_concept_code , regexp_replace (iten_number_parent, '.*,', '')  ,'NAACCR', 'NAACCR', 'Has parent item', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'), null
 from naaccr_curated
  join concept_stage on item_omop_concept_code = concept_code and concept_class_id ='NAACCR Variable'
 where iten_number_parent is not null
;


--apply internal mappings
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, concept_code_2 , concept_code_1, 'NAACCR', 'NAACCR', 'Maps to', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'), null
from internal_map
;
update concept_stage set standard_concept = null 
where concept_code in (select concept_code_1 from concept_relationship_stage where relationship_id = 'Maps to')
;
update concept_stage set concept_class_id = 'Permissible Range'
where concept_class_id ='NAACCR Value' and concept_code in 
(select concept_code from permis_range) -- need to add a script that makes this table
;

update concept_stage set concept_class_id = 'Permissible Range' 
where concept_code in (
select c.concept_code
from concept_stage cs, concept_relationship_stage r, concept_stage c, concept_numeric_stage cns
where cs.concept_code = r.concept_code_1 
and cs.vocabulary_id = r.vocabulary_id_1 
and c.concept_code = r.concept_code_2
and c.vocabulary_id = r.vocabulary_id_2
and cns.concept_code = c.concept_code
and cs.concept_code in ('230','676','446','1296'))
;

update concept_stage set standard_concept = null
where concept_class_id ='Permissible Range' and concept_code in 
(select concept_code from permis_range)
;

update concept_stage set standard_concept = null
where concept_class_id ='Permissible Range' and concept_code in 
(
select c.concept_code
from concept_stage cs, concept_relationship_stage r, concept_stage c, concept_numeric_stage cns
where cs.concept_code = r.concept_code_1 
and cs.vocabulary_id = r.vocabulary_id_1 
and c.concept_code = r.concept_code_2
and c.vocabulary_id = r.vocabulary_id_2
and cns.concept_code = c.concept_code
and cs.concept_code in ('230','676','446','1296'))
;


update concept_relationship_stage set relationship_id = 'Has permiss range'
where concept_code_2 in 
(select concept_code from permis_range)
and relationship_id = 'Has Answer'
;




update concept_relationship_stage set relationship_id = 'Has permiss range'
where concept_code_2 in 
(
select c.concept_code
from concept_stage cs, concept_relationship_stage r, concept_stage c, concept_numeric_stage cns
where cs.concept_code = r.concept_code_1 
and cs.vocabulary_id = r.vocabulary_id_1 
and c.concept_code = r.concept_code_2
and c.vocabulary_id = r.vocabulary_id_2
and cns.concept_code = c.concept_code
and cs.concept_code in ('230','676','446','1296'))
and relationship_id = 'Has Answer'
;



--Measurement to unit -- 'Has unit'
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, b.concept_code, c.concept_code, 'NAACCR', c.vocabulary_id, 'Has unit', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null	
from concept_numeric_stage n
join concept_Stage a using (concept_Code) 
join concept_relationship_Stage on concept_code_2 = a.concept_code and relationship_id ='Has permiss range'
join concept_Stage b on b.concept_Code = concept_Code_1
join concept c on  n.unit_concept_Id = c.concept_id 
where a.concept_class_id ='Permissible Range' and b.concept_class_Id ='NAACCR Variable'
and n.unit_concept_Id !=0
;
--Measurement Has type
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, b.concept_code, 'OMOP4833074', 'NAACCR', 'Metadata', 'Has type', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null	
from concept_numeric_stage n
join concept_Stage a using (concept_Code) 
join concept_relationship_Stage on concept_code_2 = a.concept_code and relationship_id ='Has permiss range'
join concept_Stage b on b.concept_Code = concept_Code_1
where a.concept_class_id ='Permissible Range' and b.concept_class_Id ='NAACCR Variable'
;

insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, concept_code, 'OMOP4833074', 'NAACCR', 'Metadata', 'Has type', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null	
from concept_stage 
where concept_code in ('2190','780','810');


--Episodes mapping to a more general concept: NAACCR Episode concepts to general "Treatment Regimen" one
insert into concept_relationship_stage (concept_id_1,concept_id_2,concept_code_1,concept_code_2,vocabulary_id_1,vocabulary_id_2,relationship_id,valid_start_date,valid_end_date,invalid_reason)
select distinct null::int, null::int, a.concept_code, 'OMOP4822256', 'NAACCR', 'Episode', 'Maps to', to_date ('19700101', 'yyyymmdd'),to_date ('20991231', 'yyyymmdd'),null	
from concept_stage a
 where domain_id = 'Episode'
;
--!!! what this script is doing? 
update concept_stage set standard_concept = 'S' where concept_code in (
select b.concept_code from concept_stage a
join concept_relationship_stage r on concept_code_1 = concept_code and relationship_id = 'Has Answer'
join concept_stage b on b.concept_code  =r.concept_code_2
 where a.domain_id = 'Episode'
--flavours of NULL remain non-standard 
 and b.concept_name not ilike '%unknown%' and b.concept_code not like '%@0'
 )
;

--https://github.com/OHDSI/OncologyWG/issues/68
update concept_stage set domain_id ='Observation', standard_concept ='S' where concept_code in (
'1390@00', '1390@82', '1390@85', '1390@86', '1390@87', '1390@88', '1390@99', '1400@00', '1400@82', '1400@85', '1400@86', '1400@87', '1400@88', '1400@99', '1410@00', '1410@82', '1410@85', '1410@86', '1410@87', '1410@88', '1410@99', '1506@00', '1506@99', '1516@00', '1516@99', '1526@00', '1526@99', '3250@0', '3250@82', '3250@85', '3250@86', '3250@87', '3250@88', '3250@99', '1290@00', '1290@99', 'All Other Sites@1290@00', 'All Other Sites@1290@99', 'Anus@1290@00', 'Anus@1290@99', 'Bladder@1290@00', 'Bladder@1290@99', 'Bones, Joints, and Soft Tissue@1290@00', 'Bones, Joints, and Soft Tissue@1290@99', 'Brain@1290@00', 'Brain@1290@99', 'Breast@1290@00', 'Breast@1290@99', 'Cervix Uteri@1290@00', 'Cervix Uteri@1290@99', 'Colon@1290@00', 'Colon@1290@99', 'Corpus Uteri@1290@00', 'Corpus Uteri@1290@99', 'Esophagus@1290@00', 'Esophagus@1290@99', 'Kidney, Renal Pelvis, and Ureter@1290@00', 'Kidney, Renal Pelvis, and Ureter@1290@99', 'Larynx@1290@00', 'Larynx@1290@99', 'Liver and Intrahepatic Bile Ducts@1290@00', 'Liver and Intrahepatic Bile Ducts@1290@99', 'Lung@1290@00', 'Lung@1290@99', 'Lymph Nodes@1290@00', 'Lymph Nodes@1290@99', 'Oral Cavity@1290@00', 'Oral Cavity@1290@99', 'Ovary@1290@00', 'Ovary@1290@99', 'Pancreas@1290@00', 'Pancreas@1290@99', 'Parotid and Other Unspecified Glands@1290@00', 'Parotid and Other Unspecified Glands@1290@99', 'Pharynx@1290@00', 'Pharynx@1290@99', 'Prostate@1290@00', 'Prostate@1290@99', 'Rectosigmoid@1290@00', 'Rectosigmoid@1290@99', 'Rectum@1290@00', 'Rectum@1290@99', 'Skin@1290@00', 'Skin@1290@99', 'Spleen@1290@00', 'Spleen@1290@99', 'Stomach@1290@00', 'Stomach@1290@99', 'Testis@1290@00', 'Testis@1290@99', 'Thyroid Gland@1290@00', 'Thyroid Gland@1290@99', 'Unknown And Ill-Defined Primary Sites@1290@98'
)
;
--https://github.com/OHDSI/OncologyWG/issues/69
update concept_stage set domain_id = 'Drug' , standard_concept =null where concept_code in (	'1390@01', '1390@02', '1390@03', '1400@01', '1410@01')
;



--usual thing: deprecate all the relationships that don't exist in stage tables
-- Build reverse relationship. This is necessary for next point
INSERT INTO concept_relationship_stage (
	concept_code_1,
	concept_code_2,
	vocabulary_id_1,
	vocabulary_id_2,
	relationship_id,
	valid_start_date,
	valid_end_date,
	invalid_reason
	)
SELECT crs.concept_code_2,
	crs.concept_code_1,
	crs.vocabulary_id_2,
	crs.vocabulary_id_1,
	r.reverse_relationship_id,
	crs.valid_start_date,
	crs.valid_end_date,
	crs.invalid_reason
FROM concept_relationship_stage crs
JOIN relationship r ON r.relationship_id = crs.relationship_id
WHERE NOT EXISTS (
		-- the inverse record
		SELECT 1
		FROM concept_relationship_stage i
		WHERE crs.concept_code_1 = i.concept_code_2
			AND crs.concept_code_2 = i.concept_code_1
			AND crs.vocabulary_id_1 = i.vocabulary_id_2
			AND crs.vocabulary_id_2 = i.vocabulary_id_1
			AND r.reverse_relationship_id = i.relationship_id
		);

-- Deprecate all relationships in concept_relationship that aren't exist in concept_relationship_stage
INSERT INTO concept_relationship_stage (
	concept_code_1,
	concept_code_2,
	vocabulary_id_1,
	vocabulary_id_2,
	relationship_id,
	valid_start_date,
	valid_end_date,
	invalid_reason
	)
SELECT a.concept_code,
	b.concept_code,
	a.vocabulary_id,
	b.vocabulary_id,
	relationship_id,
	r.valid_start_date,
	CURRENT_DATE,
	'D'
FROM concept a
JOIN concept_relationship r ON a.concept_id = concept_id_1
	AND r.invalid_reason IS NULL
JOIN concept b ON b.concept_id = concept_id_2
WHERE 'NAACCR' IN (
		a.vocabulary_id,
		b.vocabulary_id
		)
	AND NOT EXISTS (
		SELECT 1
		FROM concept_relationship_stage crs_int
		WHERE crs_int.concept_code_1 = a.concept_code
			AND crs_int.concept_code_2 = b.concept_code
			AND crs_int.vocabulary_id_1 = a.vocabulary_id
			AND crs_int.vocabulary_id_2 = b.vocabulary_id
			AND crs_int.relationship_id = r.relationship_id
		);
update concept_Stage set concept_name = trim (concept_name)
;