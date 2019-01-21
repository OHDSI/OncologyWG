
SELECT  ni.item_name
      , ni.item_number
      , ni.section
      , ni.note
      , ni.item_omop_concept_code
      , ni.item_omop_domain_id
      , nic.id
      , nic.code
      , nic.code_description
      , nic.code_omop_concept_code
      , nic.code_omop_domain_id
FROM naaccr_items ni JOIN naaccr_item_codes nic ON ni.id = nic.naaccr_item_id
WHERE ni.section = 'Treatment-1st Course'
--AND ni.item_number = '1290'
AND ni.item_omop_domain_id = 'Episode'
ORDER BY ni.item_name, nic.code
--ORDER BY code

require 'seer_api'
seer_api = SeerApi.initialize_seer_api
seer_api.surgery_titles
pp seer_api.surgery_title('Bladder')


SELECT  ni.item_name
      , ni.item_number
      , ni.section
      , ni.note
      , ni.item_omop_concept_code
      , ni.item_omop_domain_id
--       , nic.id
--       , nic.code
--       , nic.code_description
--       , nic.code_omop_concept_code
--       , nic.code_omop_domain_id
FROM naaccr_items ni LEFT JOIN naaccr_item_codes nic ON ni.id = nic.naaccr_item_id
WHERE ni.item_number IN(
 '3919'
,'774'
,'776'
,'3839'
,'3842'
,'3844'
)

ORDER BY ni.item_name, nic.code


select distinct code_omop_domain_id
from naaccr_item_codes
where code_omop_domain_id is not null

update naaccr_item_codes
set code_omop_domain_id = 'Treatment'
where code_omop_domain_id = 'Treatment Regimen'


Absence of data not recorded in OMOP.


SELECT  ni.item_name
      , ni.item_number
      , ni.section
      , ni.treatment_type
      , ni.note
      , ni.item_omop_concept_code
      , ni.item_omop_domain_id
      , nic.id
      , nic.code
      , nic.code_description
      , nic.code_omop_concept_code
      , nic.code_omop_domain_id
      , nic.code_maps_to
      , ns.title
      , nsic.icdo_code
FROM naaccr_items ni JOIN naaccr_item_codes nic ON ni.id = nic.naaccr_item_id
                     JOIN naaccr_schema_maps nsm ON nic.id = nsm.mappable_id AND nsm.mappable_type = 'NaaccrItemCode'
                     JOIN naaccr_schemas ns ON ns.id = nsm.naaccr_schema_id
                     JOIN naaccr_schema_icdo_codes nsic ON ns.id = nsic.naaccr_schema_id
WHERE ni.section = 'Treatment-1st Course'
--AND ni.item_number = '1290'
--AND ni.item_omop_domain_id = 'Episode'
AND ni.treatment_type = 'Surgery'
ORDER BY ni.item_name, nic.code
--ORDER BY code




SELECT  '?|' || nic.code_description || '|**Treatment**|NAACCR|Treatment|S|' || nic.code_omop_concept_code || '|1969-12-31|2099-12-30|' AS row
        , ni.item_name
FROM naaccr_items ni JOIN naaccr_item_codes nic ON ni.id = nic.naaccr_item_id
WHERE ni.section = 'Treatment-1st Course'
--AND ni.item_number = '1290'
--AND ni.item_omop_domain_id = 'Episode'
AND ni.treatment_type = 'Surgery'
AND ni.item_name !='RX Summ--Surg Prim Site'
AND code_omop_domain_id = 'Treatment'
ORDER BY ni.item_name, nic.code
--ORDER BY code


SELECT  ni.item_name
      , ni.item_number
      , ni.section
      , ni.treatment_type
      , ni.note
      , ni.item_omop_concept_code
      , ni.item_omop_domain_id
      , nic.id
      , nic.code
      , nic.code_description
      , nic.code_omop_concept_code
      , nic.code_omop_domain_id
      , nic.maps_to
FROM naaccr_items ni JOIN naaccr_item_codes nic ON ni.id = nic.naaccr_item_id
WHERE ni.section = 'Treatment-1st Course'
--AND ni.item_number = '1290'
--AND ni.item_omop_domain_id = 'Episode'
AND ni.treatment_type = 'Surgery'
ORDER BY ni.item_name, nic.code
--ORDER BY code