-- DDL FOR THE ONC_VALIDATION_RESULTS TABLE

IF OBJECT_ID('@resultsDatabaseSchema.onc_validation_results', 'U') IS NOT NULL
  DROP TABLE @resultsDatabaseSchema.onc_validation_results;
  
CREATE TABLE @resultsDatabaseSchema.onc_validation_results (
	analysis_id     INTEGER,
	stratum_1  VARCHAR(255),
	stratum_2  VARCHAR(255),
	stratum_3  VARCHAR(255),
	stratum_4  VARCHAR(255),
	stratum_5  VARCHAR(255),
	count_value      BIGINT
);