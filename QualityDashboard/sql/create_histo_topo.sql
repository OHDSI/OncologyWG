-- This script crates three tables (onelegged_histo, onelegged_topo, twolegged) that contain 
-- concepts. These are used to calculate how many percent of all histo/topo-related concepts
-- in a database are histology-only, topology-only and combined. The content of the three tables 
-- above should remain static as long as the vocabulary isn't updated.

drop table if exists static.remove_gen_histo;

create table static.remove_gen_histo as
with initial as (
  select 
    condition.concept_id as cancer_id, condition.concept_name as cancer_name,
    histo.concept_id as histo_id, histo.concept_name as histo_name,
    topo.concept_id as topo_id, topo.concept_name as topo_name
  from prodv5.concept condition
  join prodv5.concept_relationship r1 on r1.concept_id_1=condition.concept_id and r1.invalid_reason is null and r1.relationship_id in ('Has asso morph', 'Has Histology ICDO')
  join prodv5.concept histo on histo.concept_id=r1.concept_id_2 and histo.vocabulary_id in ('SNOMED', 'ICDO3') 
and histo.concept_name not ilike '%carcinoma in situ%' -- while we still have bad links from ICDO3 that way
  join prodv5.concept_relationship r2 on r2.concept_id_1=condition.concept_id and r2.invalid_reason is null and r2.relationship_id in ('Has finding site', 'Has Topography ICDO')
  join prodv5.concept topo on topo.concept_id=r2.concept_id_2 and topo.vocabulary_id in ('SNOMED', 'ICDO3')
  join prodv5.concept_ancestor on descendant_concept_id=condition.concept_id and ancestor_concept_id=443392 -- malignant neoplasm
  where condition.vocabulary_id in ('SNOMED', 'ICDO3')
  and condition.concept_id not in ( -- conditions with multiple topographies (threeleggeds or more)
  37151150, 4116234, 3531963, 3531964, 4095155, 4095744, 4154629, 37174907, 4082659, 37018868, 258375, 438090, 438095, 607385, 4032866, 4033318, 4095430, 4095442, 4111021, 4111952, 4116239, 4130835, 4131920, 4200399, 4227969,
  4231817, 35607522, 35619086, 36716386, 37016150, 37017112, 37018659, 37116373, 37119145, 37161210, 37166653, 37204210, 37397353, 37397555, 42539466, 44784140, 46271363, 36402816, 36517510, 36517641, 36517648, 36517686, 36517828, 
  36518077, 36518525, 36518680, 36519067, 36519224, 36519319, 36519483, 36520235, 36520345, 36520379, 36521111, 36521480, 36521484, 36521721, 36522443, 36522679, 36522756, 36524319, 36524670, 36524893, 36524972, 36525389, 
  36525877, 36526761, 36527636, 36527953, 36527965, 36528165, 36528752, 36529195, 36529497, 36529538, 36529791, 36529794, 36529807, 36529922, 36530163, 36530182, 36530827, 36531670, 36531828, 36531886, 36532205, 36532211, 
  36533228, 36533344, 36533451, 36533864, 36534147, 36534330, 36534462, 36534613, 36534820, 36534912, 36535752, 36536094, 36536120, 36537849, 36538178, 36538262, 36538714, 36538761, 36538939, 36539203, 36539743, 36541095, 
  36541172, 36541468, 36541522, 36541757, 36542009, 36542566, 36542849, 36542850, 36543421, 36543639, 36543876, 36544480, 36544656, 36544676, 36544688, 36545627, 36545720, 36545745, 36547451, 36547672, 36548338, 36549208, 
  36549453, 36549694, 36550018, 36550098, 36550198, 36550224, 36550377, 36550714, 36550850, 36550890, 36551076, 36551737, 36552872, 36553619, 36555185, 36556095, 36556303, 36556828, 36558107, 36558446, 36559243, 36559438, 
  36560088, 36561163, 36561222, 36561456, 36561822, 36562605, 36562622, 36562680, 36563336, 36563730, 36563978, 36564411, 36565173, 36565470, 36565522, 36565940, 36565985, 36566030, 36566490, 36566636, 36567474, 36567650, 
  42512431, 42512831)
),
add_mapped_histo as ( -- add invalid histo concepts mapped to standard, but still inside SNOMED and ICDO3
  select * from initial
union
  select cancer_id, cancer_name, old.concept_id as histo_id, old.concept_name as histo_name, topo_id, topo_name
  from initial
  join prodv5.concept_relationship on concept_id_1=histo_id and relationship_id='Maps to' and invalid_reason is null
  join prodv5.concept old on old.concept_id=concept_id_2 and old.vocabulary_id in ('SNOMED', 'ICDO3')
),
add_mapped_topo as ( -- add invalid topo concepts mapped to standard, but still inside SNOMED and ICDO3
  select * from add_mapped_histo
union
  select cancer_id, cancer_name, histo_id, histo_name, old.concept_id as topo_id, old.concept_name as topo_name
  from add_mapped_histo
  join prodv5.concept_relationship on concept_id_1=topo_id and relationship_id='Maps to' and invalid_reason is null
  join prodv5.concept old on old.concept_id=concept_id_2 and old.vocabulary_id in ('SNOMED', 'ICDO3')
),
add_1legged_topo as ( -- add onelegged topos: pseudo condition concepts that are a combination of topography with some generic histology (malignant neoplasm) 
  select * from add_mapped_topo
union -- add malignant neoplasms with topo as generic condition
  select t.cancer_id, t.cancer_name, t.histo_id, t.histo_name, cond.cancer_id, cond.cancer_name
  from add_mapped_topo t join (select * from add_mapped_topo where histo_id in (4312326, 4282379, 4268747, 37153816, 40548258)) cond using(topo_id)
  where t.histo_id not in (4312326, 4282379, 4268747, 37153816, 40548258)
),
remove_gen_histo as ( -- if topo conditions is constructed both from general histos (malignant neoplams etc.) and specific histos, leave only the latter
  select * from add_1legged_topo
except
  select cancer_id, cancer_name, a.histo_id, a.histo_name, topo_id, topo_name from (
    select * from add_1legged_topo where histo_id in (4312326, 4282379, 4268747, 37153816, 40548258, 4032806)
  ) a
  join (
    select * from add_1legged_topo where histo_id not in (4312326, 4282379, 4268747, 37153816, 40548258, 4032806)
  ) b using(cancer_id, cancer_name, topo_id, topo_name)
)
select * from remove_gen_histo;

drop table if exists static.unreduced;

create table static.unreduced as
-- Start with list of those topographies that happen to be in a combo for some cancer conditions. Keep the good, discard the trivial (bad)
with topo_pair(good_id, bad_id) as (values
  (4029619, 4133453),
  (4063669, 4029619),
  (4111467, 4029619),
  (4111467, 4219601),
  (4154333, 4071048),
  (4166066, 4296022),
  (4181602, 4029619),
  (4187362, 4029619),
  (4200396, 4194607),
  (4208946, 4219601),
  (4210988, 4029619),
  (4211981, 4033554),
  (4215878, 4219601),
  (4219601, 4029619),
  (4219601, 4030727),
  (4219601, 4210988),
  (4236699, 44497981),
  (4241958, 4197559),
  (4267861, 4194607),
  (4280956, 4210988),
  (4282628, 4071048),
  (4296022, 44497859),
  (4299940, 4132420),
  (4301372, 4093224),
  (4302605, 4029619),
  (4302605, 4133453),
  (4302605, 4219601),
  (4305329, 4063669),
  (4308890, 4219601),
  (4311798, 4029619),
  (4321375, 4271678),
  (44497842, 4310109),
  (44497861, 4166066),
  (44497888, 4132420),
  (44497939, 4063669),
  (44497996, 4197559),
  (44498154, 4093224),
  (44498202, 4194607),
  (44498203, 4194607),
  (44498203, 4200396),
  (44498204, 4194607),
  (44498217, 4029619),
  (44498220, 4029619),
  (44498220, 4133453),
  (44498221, 4029619),
  (44498232, 4030727),
  (44498237, 4160012),
  (44498239, 4236699),
  (44498240, 4199473),
  (44498240, 37219230),
  (44498241, 4096246),
  (44498247, 37303867),
  (44498251, 4071048)
),
remove_3legged_topo as ( -- remove records wehre there are multiple topographies of varying use
  select * from static.remove_gen_histo
except
  select cancer_id, cancer_name, histo_id, histo_name, bad_id as topo_id, bad_name as topo_name from (
    select cancer_id, cancer_name, histo_id, histo_name, topo_id as good_id, topo_name as good_name, bad_id, bad_name 
    from static.remove_gen_histo 
    join (select cancer_id, topo_id as bad_id, topo_name as bad_name from static.remove_gen_histo) using(cancer_id) where topo_id!=bad_id
  )
  join topo_pair using(good_id, bad_id)
),
add_1legged_histo as (
  select * from remove_3legged_topo
union -- add onelegged Anconditions that have only histology and not topology
  select cancer_id, cancer_name, cond.concept_id as histo_id, concept_name as histo_name, topo_id, topo_name --, histo_id as hid, histo_name as hname
  from remove_3legged_topo
  join (
    select r1.concept_id_2 as histo_id, r1.concept_id_1 as concept_id, cond.concept_name
    from prodv5.concept_relationship r1
    join prodv5.concept_ancestor on descendant_concept_id=r1.concept_id_1 and ancestor_concept_id in (443392, 433435) -- malignant neoplasm and cancer in situ
    join prodv5.concept cond on cond.concept_id=r1.concept_id_1
    left join prodv5.concept_relationship r2 on r2.concept_id_1=r1.concept_id_1 and r2.invalid_reason is null and r2.relationship_id in ('Has finding site', 'Has Topography ICDO')
    where r1.invalid_reason is null and r1.relationship_id in ('Has asso morph', 'Has Histology ICDO')
    and r1.concept_id_2 not in (4312326, 4282379, 4268747, 37153816, 40548258, 4032806) -- not general malignancies
    and r2.concept_id_2 is null -- no finding site
  ) cond using(histo_id)
)
select *  from add_1legged_histo;

drop table if exists static.cancer_histo_topo;

create table static.cancer_histo_topo as
with reduce as ( -- for all histo-topo combination pick the shortest cancer to remove "primary" and "overlapping" etc.
  select distinct
    first_value(cancer_id) over (partition by histo_id, topo_id order by length(cancer_name)) as cancer_id,
    first_value(cancer_name) over (partition by histo_id, topo_id order by length(cancer_name)) as cancer_name,
    histo_id, histo_name, topo_id, topo_name
  from static.unreduced
),
reduce_more as (  -- remove histo conditions that don't contain a topography or which contain non-generic histologies
  select reduce.* from reduce join prodv5.concept on concept_id=topo_id
  where domain_id!='Condition' or (
  domain_id='Condition' and
  topo_name not like 'Familial%' and
  topo_name not like '%HER2-positive%' and
  topo_name not like '%ereditary%' and
  topo_name not like '%ormone%' and
  topo_name not like '%infiltration%' and
  topo_name not like '%neuroma%' and
  topo_name not like 'Microsatellite%' and
  topo_name not like 'Siewert%')
)
select * from reduce_more;

drop table if exists static.onelegged_histo;

create table static.onelegged_histo as
select distinct histo_id as concept_id
from static.cancer_histo_topo 
join prodv5.concept on concept_id=histo_id and domain_id='Condition';

drop table if exists static.onelegged_topo;

create table static.onelegged_topo as
select distinct topo_id as concept_id 
from static.cancer_histo_topo 
join prodv5.concept on concept_id=topo_id and domain_id='Condition';

drop table if exists static.twolegged;

create table static.twolegged as 
select cancer_id as concept_id
from static.cancer_histo_topo 
join prodv5.concept on concept_id=cancer_id and domain_id='Condition'
except select concept_id from static.onelegged_histo
except select concept_id from static.onelegged_topo
;

drop table if exists static.all_histo_topo;

create table static.all_histo_topo as
select concept_id from static.onelegged_histo
union
select concept_id from static.onelegged_topo
union
select concept_id from static.twolegged;
