/* uses placeholders
   __schema__ - the schema containing the results from the user
   __partner_name__ - the name of the data partner to calculate results for
*/

-- update database_summary for this partner
delete from __schema__.database_summary
where partner = '__partner_name__';

insert into __schema__.database_summary
select partner, cnt as size, general, genomic, episodes 
from __schema__.patient
join (select partner, count(*) as general from __schema__.general group by partner) using(partner) 
left join (select partner, count(*) as genomic from __schema__.genomic group by partner) using(partner) 
left join (select partner, count(*) as episodes from __schema__.episodes group by partner) using(partner) 
where partner = '__partner_name__'
group by partner, cnt, general, genomic, episodes;

