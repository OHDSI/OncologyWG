/* uses placeholders
   __cdm_schema__ - the schema containing the vocabulary tables (concept, etc.)
*/

/******************************
3. Define concepts for episodes
******************************/

with cc as (
-- all episode concepts and those that have the same concept_name
  select concept_id from __cdm_schema__.concept where concept_name in (select concept_name from __cdm_schema__.concept where vocabulary_id ='Episode')
-- add HemOnc
  union select concept_id from __cdm_schema__.concept where vocabulary_id ='HemOnc'
)
select * from cc
order by concept_id;
