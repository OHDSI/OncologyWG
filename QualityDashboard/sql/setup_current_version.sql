/* 
   This script sets up the tables for calculating a specific data version that isn't necessarily
   the latest one. The script individual_report_single.sql does the actual calculation.

   uses placeholders
   @__results__ - the schema containing the results from the user
   __partner_name__ - the name of the data partner to calculate results for
   __version_number__ - the general version of the partner to calculate
*/


delete from @__results__.cur_version;

insert into @__results__.cur_version
with gene as (
  select distinct partner, cast(__version_number__ as int) as gen_version
  from @__results__.general
  where partner = '__partner_name__'
),
geno as (
  select partner, max(g.version) as cur_genomic
  from gene
  join @__results__.genomic g using(partner)
  where g.version <= gen_version
  group by partner
),
epi as (
  select partner, max(e.version) as cur_episodes
  from gene
  join @__results__.episodes e using(partner)
  where e.version <= gen_version
  group by partner
)
select partner, gen_version as cur_patient, gen_version as cur_general,
cur_genomic, cur_episodes
from gene
left join geno using(partner)
left join epi using(partner);
