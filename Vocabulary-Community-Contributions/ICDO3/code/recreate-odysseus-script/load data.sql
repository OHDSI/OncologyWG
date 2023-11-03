set schema 'snomedct';

TRUNCATE TABLE snomedct.associationrefset_f;
COPY snomedct.associationrefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Content/der2_cRefset_AssociationFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.attributevaluerefset_f;
COPY snomedct.attributevaluerefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Content/der2_cRefset_AttributeValueFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.concept_f;
COPY snomedct.concept_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_Concept_Full_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


-- QUOTE E'\b' is a trick to prevent the script from stopping due to unpaired quote (quote = none is not an option)
TRUNCATE TABLE snomedct.description_f;
COPY snomedct.description_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_Description_Full-en_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER QUOTE E'\b'
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.relationship_f;
COPY snomedct.relationship_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_Relationship_Full_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.owlexpressionrefset_f;
COPY snomedct.owlexpressionrefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_sRefset_OWLExpressionFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.stated_relationship_f;
COPY snomedct.stated_relationship_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_StatedRelationship_Full_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.textdefinition_f;
COPY snomedct.textdefinition_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Terminology/sct2_TextDefinition_Full-en_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.simplerefset_f;
COPY snomedct.simplerefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Content/der2_Refset_SimpleFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.langrefset_f;
COPY snomedct.langrefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Language/der2_cRefset_LanguageFull-en_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.extendedmaprefset_f;
COPY snomedct.extendedmaprefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Map/der2_iisssccRefset_ExtendedMapFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.simplemaprefset_f;
COPY snomedct.simplemaprefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Map/der2_sRefset_SimpleMapFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.refsetdescriptorrefset_f;
COPY snomedct.refsetdescriptorrefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_cciRefset_RefsetDescriptorFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.descriptiontyperefset_f;
COPY snomedct.descriptiontyperefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_ciRefset_DescriptionTypeFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.mrcmattributedomain_f;
COPY snomedct.mrcmattributedomain_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_cissccRefset_MRCMAttributeDomainFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.mrcmmodulescoperefset_f;
COPY snomedct.mrcmmodulescoperefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_cRefset_MRCMModuleScopeFull_INT_20231001.txt' CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.ModuleDependencyRefset_f;
COPY snomedct.ModuleDependencyRefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_ssRefset_ModuleDependencyFull_INT_20231001.txt'  CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.MRCMDomain_f;
COPY snomedct.MRCMDomain_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_sssssssRefset_MRCMDomainFull_INT_20231001.txt'  CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';


TRUNCATE TABLE snomedct.MRCMAttributeRangeRefset_f;
COPY snomedct.MRCMAttributeRangeRefset_f FROM 'C:/Data/SNOMED/SnomedCT/SnomedCT_InternationalRF2_PRODUCTION_20231001T120000Z/Full/Refset/Metadata/der2_ssccRefset_MRCMAttributeRangeFull_INT_20231001.txt'  CSV
DELIMITER E'\t' HEADER
ENCODING 'UTF8';