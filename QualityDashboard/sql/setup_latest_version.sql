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

delete from __schema__.cur_version;
insert into __schema__.cur_version
select partner, max_patient as cur_patient, max_general as cur_general,
max_genomic as cur_genomic, max_episodes as cur_episodes
from __schema__.max_versions
where partner = '__partner_name__';

delete from __schema__.measurement_combi c
using __schema__.max_versions v
where c.partner = v.partner
and c.partner = '__partner_name__'
and version = max_general;

insert into __schema__.measurement_combi (partner, measurement_concept_id, value_as_concept_id, cnt, version)
select partner, source as measurement_concept_id, standard as value_as_concept_id, cnt, version
from __schema__.general
join __schema__.max_versions using(partner)
where domain = 'q'
and partner = '__partner_name__'
and version = max_general;

insert into __schema__.measurement_combi (partner, measurement_concept_id, value_as_number, cnt, version)
select partner, source as measurement_concept_id, standard as value_as_number, cnt, version
from __schema__.general
join __schema__.max_versions using(partner)
where domain = 'a'
and partner = '__partner_name__'
and version = max_general;

delete from __schema__.general
where partner = '__partner_name__'
and domain in ('q', 'a');
