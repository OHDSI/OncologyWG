-- See https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/SNOMED/readme.md?plain=1
-- 1. Run create_source_tables.sql
-- See also https://github.com/OHDSI/Vocabulary-v5.0/blob/master/SNOMED/create_source_tables.sql
-- schema SOURCES -> snomed
-- Drop schema and dependencies
DROP SCHEMA IF EXISTS snomed CASCADE;
CREATE SCHEMA IF NOT EXISTS snomed;

DROP TABLE IF EXISTS snomed.SCT2_CONCEPT_FULL_MERGED;
CREATE TABLE snomed.SCT2_CONCEPT_FULL_MERGED
(
   ID                 BIGINT,
   EFFECTIVETIME      VARCHAR (8),
   ACTIVE             INTEGER,
   MODULEID           BIGINT,
   STATUSID           BIGINT,
   VOCABULARY_DATE    DATE,
   VOCABULARY_VERSION VARCHAR (200)
);

DROP TABLE IF EXISTS snomed.SCT2_DESC_FULL_MERGED;
CREATE TABLE snomed.SCT2_DESC_FULL_MERGED
(
   ID                   BIGINT,
   EFFECTIVETIME        VARCHAR (8),
   ACTIVE               INTEGER,
   MODULEID             BIGINT,
   CONCEPTID            BIGINT,
   LANGUAGECODE         VARCHAR (2),
   TYPEID               BIGINT,
   TERM                 VARCHAR (256),
   CASESIGNIFICANCEID   BIGINT
);

DROP TABLE IF EXISTS snomed.SCT2_RELA_FULL_MERGED;
CREATE TABLE snomed.SCT2_RELA_FULL_MERGED
(
   ID                     BIGINT,
   EFFECTIVETIME          VARCHAR (8),
   ACTIVE                 INTEGER,
   MODULEID               BIGINT,
   SOURCEID               BIGINT,
   DESTINATIONID          BIGINT,
   RELATIONSHIPGROUP      INTEGER,
   TYPEID                 BIGINT,
   CHARACTERISTICTYPEID   BIGINT,
   MODIFIERID             BIGINT
);

DROP TABLE IF EXISTS snomed.DER2_CREFSET_ASSREFFULL_MERGED;
CREATE TABLE snomed.DER2_CREFSET_ASSREFFULL_MERGED
(
    ID                         VARCHAR(256),
    EFFECTIVETIME              VARCHAR(8),
    ACTIVE                     INTEGER,
    MODULEID                   BIGINT,
    REFSETID                   BIGINT,
    REFERENCEDCOMPONENTID      BIGINT,
    TARGETCOMPONENT            BIGINT
);

DROP TABLE IF EXISTS snomed.DER2_SREFSET_SIMPLEMAPFULL_INT;
CREATE TABLE snomed.DER2_SREFSET_SIMPLEMAPFULL_INT
(
    ID                         VARCHAR(256),
    EFFECTIVETIME              VARCHAR(8),
    ACTIVE                     INTEGER,
    MODULEID                   BIGINT,
    REFSETID                   BIGINT,
    REFERENCEDCOMPONENTID      BIGINT,
    MAPTARGET                  VARCHAR(8)
);

DROP TABLE IF EXISTS snomed.DER2_CREFSET_LANGUAGE_MERGED;
CREATE TABLE snomed.DER2_CREFSET_LANGUAGE_MERGED
(
    ID                         VARCHAR(256),
    EFFECTIVETIME              VARCHAR(8),
    ACTIVE                     INTEGER,
    MODULEID                   BIGINT,
    REFSETID                   BIGINT,
    REFERENCEDCOMPONENTID      BIGINT,
    ACCEPTABILITYID            BIGINT,
    SOURCE_FILE_ID             VARCHAR(10)
);

DROP TABLE IF EXISTS snomed.DER2_SSREFSET_MODULEDEPENDENCY_MERGED;
CREATE TABLE snomed.DER2_SSREFSET_MODULEDEPENDENCY_MERGED
(
    ID                         VARCHAR(256),
    EFFECTIVETIME              VARCHAR(8),
    ACTIVE                     INTEGER,
    MODULEID                   BIGINT,
    REFSETID                   BIGINT,
    REFERENCEDCOMPONENTID      BIGINT,
    SOURCEEFFECTIVETIME        DATE,
    TARGETEFFECTIVETIME        DATE
);

DROP TABLE IF EXISTS snomed.DER2_IISSSCCREFSET_EXTENDEDMAPFULL_US;
CREATE TABLE snomed.DER2_IISSSCCREFSET_EXTENDEDMAPFULL_US
(
    ID                         VARCHAR(256),
    EFFECTIVETIME              VARCHAR(8),
    ACTIVE                     INTEGER,
    MODULEID                   BIGINT,
    REFSETID                   BIGINT,
    REFERENCEDCOMPONENTID      BIGINT,
    MAPGROUP                   INT2,
    MAPPRIORITY                TEXT,
    MAPRULE                    TEXT,
    MAPADVICE                  TEXT,
    MAPTARGET                  TEXT,
    CORRELATIONID              VARCHAR(256),
    MAPCATEGORYID              VARCHAR(256)
);

DROP TABLE IF EXISTS snomed.DER2_CREFSET_ATTRIBUTEVALUE_FULL_MERGED;
CREATE TABLE snomed.DER2_CREFSET_ATTRIBUTEVALUE_FULL_MERGED
(
   ID                         VARCHAR(256),
   EFFECTIVETIME              VARCHAR (8),
   ACTIVE                     INTEGER,
   MODULEID                   BIGINT,
   REFSETID                   BIGINT,
   REFERENCEDCOMPONENTID      BIGINT,
   VALUEID                    BIGINT
);

CREATE INDEX idx_concept_merged_id ON snomed.SCT2_CONCEPT_FULL_MERGED (ID);
CREATE INDEX idx_desc_merged_id ON snomed.SCT2_DESC_FULL_MERGED (CONCEPTID);
CREATE INDEX idx_rela_merged_id ON snomed.SCT2_RELA_FULL_MERGED (ID);
CREATE INDEX idx_lang_merged_refid ON snomed.DER2_CREFSET_LANGUAGE_MERGED (REFERENCEDCOMPONENTID);
-- 2. Download the international SNOMED file SnomedCT_InternationalRF2_Production_YYYYMMDDTzzzzzz.zip (RF2 Release) from https://www.nlm.nih.gov/healthit/snomedct/international.html.
-- 3. Extract the following files from the folder \Full\Terminology:  
-- sct2_Concept_Full_INT_YYYYMMDD.txt  
-- sct2_Description_Full-en_INT_YYYYMMDD.txt  
-- sct2_Relationship_Full_INT_YYYYMMDD.txt  
-- 
-- from the folder \Full\Refset\Map  
-- der2_sRefset_SimpleMapFull_INT_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Language  
-- der2_cRefset_LanguageFull-en_INT_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Metadata  
-- der2_ssRefset_ModuleDependencyFull_INT_YYYYMMDD.txt
-- 
-- Rename files to sct2_Concept_Full_INT.txt, sct2_Description_Full-en_INT.txt, sct2_Relationship_Full_INT.txt, der2_sRefset_SimpleMapFull_INT.txt, der2_cRefset_LanguageFull_INT.txt, der2_ssRefset_ModuleDependencyFull_INT.txt
-- 
-- 4. Download the British SNOMED file uk_sct2cl_xx.x.x__YYYYMMDD000001.zip from https://isd.digital.nhs.uk/trud3/user/authenticated/group/0/pack/26/subpack/101/releases.
-- 5. Extract the following files from the folder SnomedCT_UKClinicalRF2_Production_YYYYMMDDTzzzzzz\Full\Terminology into a working folder:  
-- sct2_Concept_Full_GB1000000_YYYYMMDD.txt  
-- sct2_Description_Full-en-GB_GB1000000_YYYYMMDD.txt  
-- sct2_Relationship_Full-GB_GB1000000_YYYYMMDD.txt  
-- 
-- from the folder \Full\Refset\Language  
-- der2_cRefset_LanguageFull-en-GB_GB1000000_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Metadata  
-- der2_ssRefset_ModuleDependencyFull_GB1000000_YYYYMMDD.txt
-- 
-- Rename files to sct2_Concept_Full-UK.txt, sct2_Description_Full-UK.txt, sct2_Relationship_Full-UK.txt, der2_cRefset_LanguageFull_UK.txt, der2_ssRefset_ModuleDependencyFull_UK.txt
-- 
-- 6. Download the US SNOMED file SnomedCT_ManagedServiceUS_PRODUCTION_USxxxxxxx_YYYYMMDDT120000Z.zip from https://www.nlm.nih.gov/healthit/snomedct/us_edition.html
-- 7. Extract the following files from the folder \Full\Terminology\ into a working folder:  
-- sct2_Concept_Full_US1000124_YYYYMMDD.txt  
-- sct2_Description_Full-en_US1000124_YYYYMMDD.txt  
-- sct2_Relationship_Full_US1000124_YYYYMMDD.txt  
-- 
-- from the folder \Full\Refset\Language  
-- der2_cRefset_LanguageFull-en_US1000124_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Metadata  
-- der2_ssRefset_ModuleDependencyFull_US1000124_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Map  
-- der2_iisssccRefset_ExtendedMapFull_US1000124_YYYYMMDD.txt
-- 
-- Remove date from file name and rename to sct2_Concept_Full_US.txt, sct2_Description_Full-en_US.txt, sct2_Relationship_Full_US.txt, der2_cRefset_LanguageFull_US.txt, der2_ssRefset_ModuleDependencyFull_US.txt, der2_iisssccRefset_ExtendedMapFull_US.txt
-- 
-- 8. Download the UK SNOMED CT Drug Extension, RF2 file uk_sct2dr_xx.x.x__YYYYMMDD000001.zip from https://isd.digital.nhs.uk/trud3/user/authenticated/group/0/pack/26/subpack/105/releases
-- 9. Extract the following files from the folder SnomedCT_UKDrugRF2_Production_20180516T000001Z\Full\Terminology\ into a working folder:  
-- sct2_Concept_Full_GB1000000_YYYYMMDD.txt  
-- sct2_Description_Full-en-GB_GB1000000_YYYYMMDD.txt  
-- sct2_Relationship_Full_GB1000000_YYYYMMDD.txt  
-- 
-- from the folder \Full\Refset\Language  
-- der2_cRefset_LanguageFull-en-GB_GB1000001_YYYYMMDD.txt
-- 
-- from the folder \Full\Refset\Metadata  
-- der2_ssRefset_ModuleDependencyFull_GB1000001_YYYYMMDD.txt
-- 
-- Rename files to sct2_Concept_Full_GB_DE.txt, sct2_Description_Full-en-GB_DE.txt, sct2_Relationship_Full_GB_DE.txt, der2_cRefset_LanguageFull_GB_DE.txt, der2_ssRefset_ModuleDependencyFull_GB_DE.txt
-- 
-- 10. Extract
-- - der2_cRefset_AssociationFull_INT_YYYYMMDD.txt from SnomedCT_InternationalRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AssociationUKCLFull_GBxxxxxxx_YYYYMMDD.txt from uk_sct2cl_xx.x.x__YYYYMMDD000001\SnomedCT_UKClinicalRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AssociationFull_USxxxxxxx_YYYYMMDD.txt from SnomedCT_USEditionRF2_PRODUCTION_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AssociationUKDGFull_GBxxxxxxx_YYYYMMDD.txt from SnomedCT_UKDrugRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- Rename to der2_cRefset_AssociationFull_INT.txt, der2_cRefset_AssociationFull_UK.txt, der2_cRefset_AssociationFull_US.txt and der2_cRefset_AssociationFull_GB_DE.txt
-- 
-- 11. Extract
-- - der2_cRefset_AttributeValueFull_INT_YYYYMMDD.txt from SnomedCT_InternationalRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AttributeValueUKCLFull_GBxxxxxxx_YYYYMMDD.txt from uk_sct2cl_xx.x.x__YYYYMMDD000001\SnomedCT_UKClinicalRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AttributeValueFull_USxxxxxxx_YYYYMMDD.txt from SnomedCT_USEditionRF2_PRODUCTION_YYYYMMDDTzzzzzz\Full\Refset\Content
-- - der2_cRefset_AttributeValueUKDGFull_GBxxxxxxx_YYYYMMDD.txt from SnomedCT_UKDrugRF2_Production_YYYYMMDDTzzzzzz\Full\Refset\Content
-- Rename to der2_cRefset_AttributeValueFull_INT.txt, der2_cRefset_AttributeValueFull_UK.txt, der2_cRefset_AttributeValueFull_US.txt and der2_cRefset_AttributeValue_GB_DE.txt
-- 
-- 12. Run in devv5 (with fresh vocabulary date and version): SELECT sources.load_input_tables('SNOMED',TO_DATE('20180131','YYYYMMDD'),'Snomed Release 20180131');
-- See https://github.com/OHDSI/Vocabulary-v5.0/blob/44978ec6fd5cf8ad4d8e5cf1171d869c1767c2b5/working/packages/load_input_tables/load_input_tables.sql#L4
-- Modified only for SNOMED
CREATE OR REPLACE FUNCTION load_input_tables (
  pvocabularyid text,
  pvocabularydate date = NULL::date,
  pvocabularyversion text = NULL::text
)
RETURNS void AS
$body$
declare
--  pVocabularyPath varchar (1000) := (SELECT var_value FROM devv5.config$ WHERE var_name='vocabulary_load_path');
  pVocabularyPath varchar (1000) := 'C:/Data/SNOMED/OHDSIvocabulary/';
  z varchar(100);
begin
  pVocabularyID=UPPER(pVocabularyID);
--  pVocabularyPath=pVocabularyPath||pVocabularyID||'/';
  case pVocabularyID
  when 'SNOMED' then
      truncate table snomed.sct2_concept_full_merged, snomed.sct2_desc_full_merged, snomed.sct2_rela_full_merged, snomed.der2_crefset_assreffull_merged, snomed.der2_crefset_attributevalue_full_merged, snomed.der2_crefset_language_merged;
      drop index snomed.idx_concept_merged_id;
      drop index snomed.idx_desc_merged_id;
      drop index snomed.idx_rela_merged_id;
      drop index snomed.idx_lang_merged_refid;
      --loading sct2_concept_full_merged
      execute 'COPY snomed.sct2_concept_full_merged (id,effectivetime,active,moduleid,statusid) FROM '''||pVocabularyPath||'sct2_Concept_Full_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_concept_full_merged (id,effectivetime,active,moduleid,statusid) FROM '''||pVocabularyPath||'sct2_Concept_Full-UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_concept_full_merged (id,effectivetime,active,moduleid,statusid) FROM '''||pVocabularyPath||'sct2_Concept_Full_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_concept_full_merged (id,effectivetime,active,moduleid,statusid) FROM '''||pVocabularyPath||'sct2_Concept_Full_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      update snomed.sct2_concept_full_merged set vocabulary_date=COALESCE(pVocabularyDate,current_date), vocabulary_version=COALESCE(pVocabularyVersion,pVocabularyID||' '||current_date);
      --delete duplicate records
      DELETE FROM snomed.sct2_concept_full_merged s WHERE EXISTS (SELECT 1 FROM snomed.sct2_concept_full_merged s_int 
      	WHERE s_int.id = s.id AND s_int.effectivetime=s.effectivetime
        AND s_int.active = s.active AND s_int.moduleid=s.moduleid
        AND s_int.statusid=s.statusid AND s_int.ctid > s.ctid);
      --loading sct2_desc_full_merged
      execute 'COPY snomed.sct2_desc_full_merged FROM '''||pVocabularyPath||'sct2_Description_Full-en_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_desc_full_merged FROM '''||pVocabularyPath||'sct2_Description_Full-UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_desc_full_merged FROM '''||pVocabularyPath||'sct2_Description_Full-en_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_desc_full_merged FROM '''||pVocabularyPath||'sct2_Description_Full-en-GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --delete duplicate records
      DELETE FROM snomed.sct2_desc_full_merged s WHERE EXISTS (SELECT 1 FROM snomed.sct2_desc_full_merged s_int 
      	WHERE s_int.id = s.id AND s_int.effectivetime=s.effectivetime
        AND s_int.active = s.active AND s_int.moduleid=s.moduleid
        AND s_int.conceptid=s.conceptid AND s_int.languagecode=s.languagecode
        AND s_int.typeid = s.typeid AND s_int.term=s.term
        AND s_int.casesignificanceid = s.casesignificanceid AND s_int.ctid > s.ctid);
      --loading sct2_rela_full_merged
      execute 'COPY snomed.sct2_rela_full_merged FROM '''||pVocabularyPath||'sct2_Relationship_Full_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_rela_full_merged FROM '''||pVocabularyPath||'sct2_Relationship_Full-UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_rela_full_merged FROM '''||pVocabularyPath||'sct2_Relationship_Full_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.sct2_rela_full_merged FROM '''||pVocabularyPath||'sct2_Relationship_Full_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --delete duplicate records
      DELETE FROM snomed.sct2_rela_full_merged s WHERE EXISTS (SELECT 1 FROM snomed.sct2_rela_full_merged s_int 
      	WHERE s_int.id = s.id AND s_int.effectivetime=s.effectivetime
        AND s_int.active = s.active AND s_int.moduleid=s.moduleid
        AND s_int.sourceid=s.sourceid AND s_int.destinationid=s.destinationid
        AND s_int.relationshipgroup = s.relationshipgroup AND s_int.typeid=s.typeid
        AND s_int.characteristictypeid = s.characteristictypeid AND s_int.modifierid=s.modifierid
        AND s_int.ctid > s.ctid);
      --loading der2_crefset_assreffull_merged
      execute 'COPY snomed.der2_crefset_assreffull_merged FROM '''||pVocabularyPath||'der2_cRefset_AssociationFull_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_assreffull_merged FROM '''||pVocabularyPath||'der2_cRefset_AssociationFull_UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_assreffull_merged FROM '''||pVocabularyPath||'der2_cRefset_AssociationFull_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_assreffull_merged FROM '''||pVocabularyPath||'der2_cRefset_AssociationFull_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --delete duplicate records
      DELETE FROM snomed.der2_crefset_assreffull_merged s WHERE EXISTS (SELECT 1 FROM snomed.der2_crefset_assreffull_merged s_int 
      	WHERE s_int.id = s.id AND s_int.effectivetime=s.effectivetime
        AND s_int.active = s.active AND s_int.moduleid=s.moduleid
        AND s_int.refsetid=s.refsetid AND s_int.referencedcomponentid=s.referencedcomponentid
        AND s_int.targetcomponent = s.targetcomponent AND s_int.ctid > s.ctid);
      --loading der2_crefset_attributevalue_full_merged
      execute 'COPY snomed.der2_crefset_attributevalue_full_merged FROM '''||pVocabularyPath||'der2_cRefset_AttributeValueFull_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_attributevalue_full_merged FROM '''||pVocabularyPath||'der2_cRefset_AttributeValueFull_UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_attributevalue_full_merged FROM '''||pVocabularyPath||'der2_cRefset_AttributeValueFull_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_crefset_attributevalue_full_merged FROM '''||pVocabularyPath||'der2_cRefset_AttributeValueFull_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --delete duplicate records
      DELETE FROM snomed.der2_crefset_attributevalue_full_merged s WHERE EXISTS (SELECT 1 FROM snomed.der2_crefset_attributevalue_full_merged s_int 
      	WHERE s_int.id = s.id AND s_int.effectivetime=s.effectivetime
        AND s_int.active = s.active AND s_int.moduleid=s.moduleid
        AND s_int.refsetid=s.refsetid AND s_int.referencedcomponentid=s.referencedcomponentid
        AND s_int.valueid = s.valueid AND s_int.ctid > s.ctid);
      CREATE INDEX idx_concept_merged_id ON snomed.sct2_concept_full_merged (id);
      CREATE INDEX idx_desc_merged_id ON snomed.sct2_desc_full_merged (conceptid);
      CREATE INDEX idx_rela_merged_id ON snomed.sct2_rela_full_merged (id);
      analyze snomed.sct2_concept_full_merged;
      analyze snomed.sct2_desc_full_merged;
      analyze snomed.sct2_rela_full_merged;
      --loading der2_sRefset_SimpleMapFull_INT
      truncate table snomed.der2_srefset_simplemapfull_int;
      execute 'COPY snomed.der2_srefset_simplemapfull_int FROM '''||pVocabularyPath||'der2_sRefset_SimpleMapFull_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --loading der2_crefset_language_merged
      execute 'COPY snomed.der2_crefset_language_merged (id,effectivetime,active,moduleid,refsetId,referencedComponentId,acceptabilityId) FROM '''||pVocabularyPath||'der2_cRefset_LanguageFull_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      update snomed.der2_crefset_language_merged set source_file_id='INT' where source_file_id is null;
      execute 'COPY snomed.der2_crefset_language_merged (id,effectivetime,active,moduleid,refsetId,referencedComponentId,acceptabilityId) FROM '''||pVocabularyPath||'der2_cRefset_LanguageFull_UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      update snomed.der2_crefset_language_merged set source_file_id='UK' where source_file_id is null;
      execute 'COPY snomed.der2_crefset_language_merged (id,effectivetime,active,moduleid,refsetId,referencedComponentId,acceptabilityId) FROM '''||pVocabularyPath||'der2_cRefset_LanguageFull_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      update snomed.der2_crefset_language_merged set source_file_id='US' where source_file_id is null;
      execute 'COPY snomed.der2_crefset_language_merged (id,effectivetime,active,moduleid,refsetId,referencedComponentId,acceptabilityId) FROM '''||pVocabularyPath||'der2_cRefset_LanguageFull_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      update snomed.der2_crefset_language_merged set source_file_id='GB_DE' where source_file_id is null;
      CREATE INDEX idx_lang_merged_refid ON snomed.der2_crefset_language_merged (referencedcomponentid);
      analyze snomed.der2_crefset_language_merged;
      --loading der2_ssrefset_moduledependency_merged
      truncate table snomed.der2_ssrefset_moduledependency_merged;
      execute 'COPY snomed.der2_ssrefset_moduledependency_merged FROM '''||pVocabularyPath||'der2_ssRefset_ModuleDependencyFull_INT.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_ssrefset_moduledependency_merged FROM '''||pVocabularyPath||'der2_ssRefset_ModuleDependencyFull_UK.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_ssrefset_moduledependency_merged FROM '''||pVocabularyPath||'der2_ssRefset_ModuleDependencyFull_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      execute 'COPY snomed.der2_ssrefset_moduledependency_merged FROM '''||pVocabularyPath||'der2_ssRefset_ModuleDependencyFull_GB_DE.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
      --loading der2_iisssccrefset_extendedmapfull_us
      truncate table snomed.der2_iisssccrefset_extendedmapfull_us;
      execute 'COPY snomed.der2_iisssccrefset_extendedmapfull_us FROM '''||pVocabularyPath||'der2_iisssccRefset_ExtendedMapFull_US.txt'' delimiter E''\t'' csv quote E''\b'' HEADER';
--      PERFORM sources_archive.AddVocabularyToArchive('SNOMED', ARRAY['sct2_concept_full_merged','sct2_desc_full_merged','sct2_rela_full_merged','der2_crefset_assreffull_merged','der2_crefset_language_merged',
--        'der2_srefset_simplemapfull_int','der2_ssrefset_moduledependency_merged','der2_iisssccrefset_extendedmapfull_us','der2_crefset_attributevalue_full_merged'], COALESCE(pVocabularyDate,current_date), 'archive.snomed_version', 10);
  else
      RAISE EXCEPTION 'Vocabulary with id=% not found', pVocabularyID;
  end case;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

SELECT load_input_tables('SNOMED',TO_DATE('20231001','YYYYMMDD'),'Snomed Release 20231001');
-- Next steps are not needed (these are to put the SNOMED vocab in the OMOP tables)?
-- 13. Run load_stage.sql
-- 14. Run generic_update: devv5.GenericUpdate();