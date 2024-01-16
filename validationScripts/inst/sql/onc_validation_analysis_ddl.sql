-- DDL FOR THE ONC_VALIDATION_ANALYSIS TABLE

IF OBJECT_ID('@resultsDatabaseSchema.onc_validation_analysis', 'U') IS NOT NULL
  DROP TABLE @resultsDatabaseSchema.onc_validation_analysis;
  
CREATE TABLE @resultsDatabaseSchema.ONC_VALIDATION_ANALYSIS (
	analysis_id     INTEGER,
	analysis_name   VARCHAR(255),
	stratum_1_name  VARCHAR(255),
	stratum_2_name  VARCHAR(255),
	stratum_3_name  VARCHAR(255),
	stratum_4_name  VARCHAR(255),
	stratum_5_name  VARCHAR(255),
	is_default      INTEGER,
	category        VARCHAR(255)
);