/* This table receives concepts that aren't in static.additional_conditions or static.lab_category
   and that are also no cancer concepts. Some of them (like 81382) are erroneously extracted
   as cancer conepts, while others (like 30968) shouldn't be extracted at all but still are for
   some reason. We collect these concepts here to exclude them from all reports on cancer.
*/

create table if not exists static.excluded_concepts (
	concept_id int
);
delete from static.excluded_concepts;

insert into static.excluded_concepts
with excluded(concept_id) as (values
  (30968), (40399075), (40426644), (40399098), (81382), (4055225), (4059298), (4059299), (4071732), (46272568)
)
select distinct concept_id
from excluded;
