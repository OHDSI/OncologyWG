/* create the Full S-CT data tables */
/* Change the table suffix for different release type. _f stands for full, _d stands for delta, _s stands for snapshot */

/*CREATE TABLE concept_f*/
DROP TABLE IF EXISTS snomedct.concept_f CASCADE;
CREATE TABLE snomedct.concept_f(
  id BIGINT NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  definitionstatusid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE description_f*/
DROP TABLE IF EXISTS snomedct.description_f CASCADE;
CREATE TABLE snomedct.description_f(
  id BIGINT NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  conceptid BIGINT NOT NULL,
  languagecode VARCHAR(3) NOT NULL,
  typeid BIGINT NOT NULL,
  term TEXT NOT NULL,
  casesignificanceid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE textdefinition_f*/
DROP TABLE IF EXISTS snomedct.textdefinition_f CASCADE;
CREATE TABLE snomedct.textdefinition_f(
  id BIGINT NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  conceptid BIGINT NOT NULL,
  languagecode VARCHAR(3) NOT NULL,
  typeid BIGINT NOT NULL,
  term TEXT NOT NULL,
  casesignificanceid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE relation_f*/
DROP TABLE IF EXISTS snomedct.relationship_f CASCADE;
CREATE TABLE snomedct.relationship_f(
  id BIGINT NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  sourceid BIGINT NOT NULL,
  destinationid BIGINT NOT NULL,
  relationshipgroup INT NOT NULL,
  typeid BIGINT NOT NULL,
  characteristictypeid BIGINT NOT NULL,
  modifierid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE stated_relationship_f*/
DROP TABLE IF EXISTS snomedct.stated_relationship_f CASCADE;
CREATE TABLE snomedct.stated_relationship_f(
  id BIGINT NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  sourceid BIGINT NOT NULL,
  destinationid BIGINT NOT NULL,
  relationshipgroup INT NOT NULL,
  typeid BIGINT NOT NULL,
  characteristictypeid BIGINT NOT NULL,
  modifierid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE langrefset_f*/
DROP TABLE IF EXISTS snomedct.langrefset_f CASCADE;
CREATE TABLE snomedct.langrefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  acceptabilityid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE associationrefset_f*/
DROP TABLE IF EXISTS snomedct.associationrefset_f CASCADE;
CREATE TABLE snomedct.associationrefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  targetcomponentid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE attributevaluerefset_f*/
DROP TABLE IF EXISTS snomedct.attributevaluerefset_f CASCADE;
CREATE TABLE snomedct.attributevaluerefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  valueid VARCHAR(18) NOT NULL,
  PRIMARY KEY(id, effectivetime)
);


/*CREATE TABLE simplerefset_f*/
DROP TABLE IF EXISTS snomedct.simplerefset_f CASCADE;
CREATE TABLE snomedct.simplerefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE simplemaprefset_f*/
DROP TABLE IF EXISTS snomedct.simplemaprefset_f CASCADE;
CREATE TABLE snomedct.simplemaprefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  maptarget VARCHAR(200) NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE extendedmaprefset_f*/
DROP TABLE IF EXISTS snomedct.extendedmaprefset_f CASCADE;
CREATE TABLE snomedct.extendedmaprefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  mapGroup INT NOT NULL,
  mapPriority INT NOT NULL,
  mapRule TEXT NOT NULL,
  mapAdvice TEXT NOT NULL,
  mapTarget VARCHAR(200),
  correlationId BIGINT NOT NULL,
  mapCategoryId BIGINT NOT NULL,
  PRIMARY KEY(id, effectivetime)
);

/*CREATE TABLE MRCMModuleScoperefset_f*/
DROP TABLE IF EXISTS snomedct.MRCMModuleScoperefset_f CASCADE;
CREATE TABLE snomedct.MRCMModuleScoperefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  mrcmRuleRefsetId BIGINT NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);

/*CREATE TABLE RefsetDescriptorrefset_f*/
DROP TABLE IF EXISTS snomedct.RefsetDescriptorrefset_f CASCADE;
CREATE TABLE snomedct.RefsetDescriptorrefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  attributeDescription BIGINT NOT NULL,
  attributeType BIGINT NOT NULL,
  attributeOrder INTEGER NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);

/*CREATE TABLE DescriptionTyperefset_f*/
DROP TABLE IF EXISTS snomedct.DescriptionTyperefset_f CASCADE;
CREATE TABLE snomedct.DescriptionTyperefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  descriptionFormat BIGINT NOT NULL,
  descriptionLength INTEGER NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);


/*CREATE TABLE MRCMAttributeDomain_f*/
DROP TABLE IF EXISTS snomedct.MRCMAttributeDomain_f CASCADE;
CREATE TABLE snomedct.MRCMAttributeDomain_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  domainId BIGINT NOT NULL,
  grouped BIT NOT NULL,
  attributeCardinality VARCHAR(12) NOT NULL,
  attributeInGroupCardinality VARCHAR(12) NOT NULL,
  ruleStrengthId BIGINT NOT NULL,
  contentTypeId BIGINT NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);

/*CREATE TABLE MRCMAttributeDomain_f*/
DROP TABLE IF EXISTS snomedct.MRCMAttributeRangeRefset_f CASCADE;
CREATE TABLE snomedct.MRCMAttributeRangeRefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  rangeConstraint TEXT NOT NULL,
  attributeRule TEXT NOT NULL,
  ruleStrengthId BIGINT NOT NULL,
  contentTypeId BIGINT NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);

/*CREATE TABLE MRCMDomain_f*/
DROP TABLE IF EXISTS snomedct.MRCMDomain_f CASCADE;
CREATE TABLE snomedct.MRCMDomain_f(  
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  domainConstraint TEXT,
  parentDomain TEXT,
  proximalPrimitiveConstraint TEXT,
  proximalPrimitiveRefinement TEXT,
  domainTemplateForPrecoordination TEXT,
  domainTemplateForPostcoordination TEXT,
  guideURL TEXT NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);


/*CREATE TABLE ModuleDependencyRefset_f*/
DROP TABLE IF EXISTS snomedct.ModuleDependencyRefset_f CASCADE;
CREATE TABLE snomedct.ModuleDependencyRefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  sourceEffectiveTime DATE NOT NULL,
  targetEffectiveTime DATE NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);

/*CREATE TABLE OWLExpressionRefset_f*/
DROP TABLE IF EXISTS snomedct.OWLExpressionRefset_f CASCADE;
CREATE TABLE snomedct.OWLExpressionRefset_f(
  id varchar(36) NOT NULL,
  effectivetime DATE NOT NULL,
  active BIT NOT NULL,
  moduleid BIGINT NOT NULL,
  refsetid BIGINT NOT NULL,
  referencedcomponentid BIGINT NOT NULL,
  owlexpression TEXT NOT NULL,
  PRIMARY KEY (id, effectiveTime)
);