----all duplicates
SELECT naaccr_items.item_number
     , naaccr_item_codes.code
     , naaccr_schema_icdo_codes.icdo_code
     , COUNT(*) AS total
FROM naaccr_items JOIN naaccr_versions ON naaccr_items.naaccr_version_id = naaccr_versions.id
                  JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id
                  JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id --AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode'
                  JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id
                  JOIN naaccr_schema_icdo_codes ON naaccr_schemas.id = naaccr_schema_icdo_codes.naaccr_schema_id AND naaccr_schema_icdo_codes.icdo_type = 'ICDO Topography Morphology'
WHERE naaccr_items.section IN('Cancer Identification', 'Stage/Prognostic Factors')
--AND naaccr_items.item_number = '2820'
AND naaccr_items.item_omop_domain_id NOT IN('None', 'Date')
AND naaccr_versions.version = '18'
GROUP BY naaccr_items.item_number, naaccr_item_codes.code, naaccr_schema_icdo_codes.icdo_code
HAVING COUNT(*) > 1



--all item codes
SELECT  naaccr_items.item_name
      , naaccr_items.item_number
      , naaccr_items.item_omop_concept_code
      , naaccr_item_codes.code
      , naaccr_item_codes.code_description
      , naaccr_item_codes.code_omop_concept_code
FROM naaccr_items JOIN naaccr_versions ON naaccr_items.naaccr_version_id = naaccr_versions.id
                  JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id
WHERE naaccr_items.section IN('Cancer Identification', 'Stage/Prognostic Factors')
AND naaccr_items.item_omop_domain_id NOT IN('None', 'Date')
AND naaccr_versions.version = '18'
AND naaccr_items.item_number = '1182'
order by code_omop_concept_code, naaccr_item_codes.code


--all item codes and icdo codes
SELECT  naaccr_items.item_name
      , naaccr_items.item_number
      , naaccr_items.item_omop_concept_code
      , naaccr_item_codes.code
      , naaccr_item_codes.code_description
      , naaccr_item_codes.code_omop_concept_code
      , naaccr_staging_algorithms.algorithm
      , naaccr_schemas.title
      , naaccr_schemas.seer_id
      , naaccr_schemas.schema_selection_table
      , naaccr_schema_icdo_codes.icdo_code
FROM naaccr_items JOIN naaccr_versions ON naaccr_items.naaccr_version_id = naaccr_versions.id
                  JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id
                  JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode'
                  JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id
                  JOIN naaccr_staging_algorithms ON naaccr_staging_algorithms.id = naaccr_schemas.naaccr_staging_algorithm_id
                  JOIN naaccr_schema_icdo_codes ON naaccr_schemas.id = naaccr_schema_icdo_codes.naaccr_schema_id AND naaccr_schema_icdo_codes.icdo_type = 'ICDO Topography Morphology'
WHERE naaccr_items.section IN('Cancer Identification', 'Stage/Prognostic Factors')
AND naaccr_items.item_omop_domain_id NOT IN('None', 'Date')
AND naaccr_versions.version = '18'
AND naaccr_items.item_number = '762'


--all icdo code per item code
SELECT  naaccr_items.item_name
      , naaccr_items.item_number
      , naaccr_items.item_omop_concept_code
      , naaccr_item_codes.code
      , naaccr_item_codes.code_description
      , naaccr_item_codes.code_omop_concept_code
      , naaccr_staging_algorithms.algorithm
      , naaccr_schemas.title
      , naaccr_schemas.seer_id
      , naaccr_schemas.schema_selection_table
      , naaccr_schema_icdo_codes.icdo_code
FROM naaccr_items JOIN naaccr_versions ON naaccr_items.naaccr_version_id = naaccr_versions.id
                  JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id
                  JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode'
                  JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id
                  JOIN naaccr_staging_algorithms ON naaccr_staging_algorithms.id = naaccr_schemas.naaccr_staging_algorithm_id
                  JOIN naaccr_schema_icdo_codes ON naaccr_schemas.id = naaccr_schema_icdo_codes.naaccr_schema_id AND naaccr_schema_icdo_codes.icdo_type = 'ICDO Topography Morphology'

WHERE naaccr_items.section IN('Cancer Identification', 'Stage/Prognostic Factors')
AND naaccr_items.item_omop_domain_id NOT IN('None', 'Date')
AND naaccr_versions.version = '18'
AND naaccr_items.item_number = '1182'
AND naaccr_schema_icdo_codes.icdo_code = '8000/0-C00.3'
AND naaccr_item_codes.code = '0'



SELECT DISTINCT
item_number
FROM(
----all duplicates
SELECT naaccr_items.item_number
     , naaccr_item_codes.code
     , naaccr_schema_icdo_codes.icdo_code
     , COUNT(*) AS total
FROM naaccr_items JOIN naaccr_versions ON naaccr_items.naaccr_version_id = naaccr_versions.id
                  JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id
                  JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id --AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode'
                  JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id
                  JOIN naaccr_schema_icdo_codes ON naaccr_schemas.id = naaccr_schema_icdo_codes.naaccr_schema_id AND naaccr_schema_icdo_codes.icdo_type = 'ICDO Topography Morphology'
WHERE naaccr_items.section IN('Cancer Identification', 'Stage/Prognostic Factors')
--AND naaccr_items.item_number = '2820'
AND naaccr_items.item_omop_domain_id NOT IN('None', 'Date')
AND naaccr_versions.version = '18'
GROUP BY naaccr_items.item_number, naaccr_item_codes.code, naaccr_schema_icdo_codes.icdo_code
HAVING COUNT(*) > 1
) data