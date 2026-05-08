options (skip=1)
load data
infile concept_numeric.csv 
into table concept_numeric
replace
fields terminated by ','
trailing nullcols
(        concept_id
       , value_as_number
       , unit_concept_id
       , operator_concept_id
    )