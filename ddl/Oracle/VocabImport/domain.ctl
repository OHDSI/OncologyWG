options (skip=1)
load data
infile DOMAIN.csv 
into table DOMAIN
replace
fields terminated by '\t'
trailing nullcols
(
  domain_id,
  domain_name,
  domain_concept_id
)