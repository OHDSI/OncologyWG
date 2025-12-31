/* uses placeholders
   __schema__ - the schema containing the results from the user
   __partner_name__ - the name of the data partner to calculate results for
*/

delete from __schema__.max_versions;
insert into __schema__.max_versions
with max_pat as (
  select partner, max(version) as max_patient
  from __schema__.patient
  group by partner
),
max_gene as ( -- general and measurement have the same version, because the come from the same input file.
  select partner, max(version) as max_general
  from __schema__.general
  group by partner
),
max_geno as (
  select partner, max(version) as max_genomic
  from __schema__.genomic
  group by partner
),
max_epi as (
  select partner, max(version) as max_episodes
  from __schema__.episodes
  group by partner
)
select partner, max_patient, max_general, max_genomic, max_episodes
from max_pat
left join max_gene using(partner)
left join max_geno using(partner)
left join max_epi using(partner)
order by partner;
