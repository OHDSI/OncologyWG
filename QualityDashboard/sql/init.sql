create schema if not exists __schema__ Authorization postgres;

create table if not exists __schema__.general (
    partner varchar(20),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );

create table if not exists __schema__.general_cleaned (
    partner varchar(20),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );
  
create table if not exists __schema__.genomic (
    partner varchar(20),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );

create table if not exists __schema__.episodes (
    partner varchar(20),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );

create table if not exists __schema__.patient (
    partner varchar(20),
    cnt int,
	first_event date,
	last_event date,
	observation_start date,
	observation_end date,
	cdm_version varchar(10),
	data_type varchar(20),
	updates int
  );

create table if not exists __schema__.database_summary (
    partner varchar(20),
    size int,
    general bigint,
    genomic bigint,
    episodes bigint,
	lab_tests bigint,
	non_cancer bigint
  );

create table if not exists __schema__.individual_concept_report (
    partner varchar(20),
    concept varchar(10),
    concept_id bigint,
    concept_name varchar(255),
    vocabulary_id varchar(20),
    domain_id varchar(20),
    is_domain varchar(20),
    critique varchar(255),
    records bigint
  );

create table if not exists __schema__.standard_summary_report (
    partner varchar(20),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists results.standard_summary_report_cleaned (
    partner varchar(20),
    critique varchar(255),
    records bigint,
    "record_%" numeric,
    concepts int,
    "concept_%" numeric
  );

create table if not exists __schema__.source_summary_report (
    partner varchar(20),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists __schema__.mapping_summary_report (
    partner varchar(20),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists __schema__.domain_weights (
    partner varchar(20),
    domain varchar(20),
    records bigint,
    "record_%" numeric
  );
  
create table if not exists __schema__.rolled_up_tumor_types (
    partner varchar(20),
    cancer_type varchar(30),
    records bigint,
    "record_%" numeric
  );  

create table if not exists __schema__.records_and_concepts_in_source_and_standard (
    partner varchar(20),
    size int,
    t_records bigint,
    records_patient numeric,
    t_source bigint,
    source_patient numeric,
    t_standard bigint,
    standard_patient numeric
);

create table if not exists __schema__.number_of_records_per_domain (
    partner varchar(20),
    domain varchar(20),
    records bigint,
    "records_%" numeric,
    concepts bigint,
    "concept_%" numeric
);

create table if not exists __schema__.number_of_records_per_vocabulary (
    partner varchar(20),
    domain varchar(20),
    vocabulary varchar(20),
    records bigint,
    "records_%" numeric,
    concepts bigint,
    "concept_%" numeric
);
  
create table if not exists __schema__.rolled_up_tumor_types_for_each_partner (
    partner varchar(20),
    cancer_type varchar(30),
    records bigint,
    "record_%" numeric
  );  

create table if not exists __schema__.count_existing_source_concepts (
    partner varchar(20),
    in_vocab varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concept_%" numeric
);

create table if not exists __schema__.standard_concepts_in_standard_fields (
    partner varchar(20),
    concept varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.domain_for_standard_concepts (
    partner varchar(20),
    domain varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.standard_concept_report (
    partner varchar(20),
    critique varchar(30),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.top_standard_concept_errors (
    concept_id int,
    concept_name varchar(255),
    vocabulary_id varchar(20),
    concept_code varchar(50),
    concept_class_id varchar(20),
    critique varchar(30),
    fix varchar(100)
);

create table if not exists __schema__.top_wrong_domain_concepts (
    partner varchar(20),
    standard int,
    concept_name varchar(255),
    vocabulary_id varchar(20),
    is_domain varchar(20),
    shouldbe_domain varchar(20),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.mapping_from_source_to_standard (
    partner varchar(20),
    source varchar(10),
    mapping varchar(20),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.histo_topo_percent (
    partner varchar(20),
	onelegged_records bigint,
    onelegged_perc numeric,
	shallow_records bigint,
    shallow_perc numeric,
	both_records bigint,
	both_perc numeric
);

create table if not exists __schema__.histo_topo_individual (
    partner varchar(20),
    concept_id bigint,
    concept_name varchar(255),
    critique varchar(255),
    records bigint
  );

create table if not exists __schema__.measurement (
    partner varchar(20),
    measurement_concept_id int,
    value_as_concept_id int,
    unit_concept_id int,
    range_low numeric,
    range_high numeric,
    p_03 numeric,
    p_25 numeric,
    median numeric,
    p_75 numeric,
    p_97 numeric,
	cnt int
);

create table if not exists __schema__.stages (
    partner varchar(20),
	bad_cnt bigint,
    all_cnt bigint,
    bad_from_all numeric,
    all_from_total numeric,
	bad_from_total numeric
);

create table if not exists __schema__.grades (
    partner varchar(20),
	bad_cnt bigint,
    all_cnt bigint,
    bad_from_all numeric,
    all_from_total numeric,
	bad_from_total numeric
);

create table if not exists __schema__.mets (
    partner varchar(20),
	bad_cnt bigint,
    all_cnt bigint,
    bad_from_all numeric,
    all_from_total numeric,
	bad_from_total numeric
);

create table if not exists __schema__.lab_long_report (
	partner varchar(20),
	cat varchar(60),
	measurement_id int,
	measurement_name varchar(255),
	records int,
	percent numeric,
	value_id int,
	value_name varchar(255),
	concept_critique varchar(20),
	pct_of_concept_recs numeric,
	unit_id int,
	unit_name varchar(255),
    range_low numeric,
    range_high numeric,
	range varchar(10),
	values varchar(10),
	spread varchar(10),
	unit varchar(10),
	outliers varchar(10),
	pct_of_value_recs numeric
);

create table if not exists __schema__.lab_summary (
	partner varchar(20),
	cat varchar(60),
	concept_records int,
	number int,
	flavor_null int,
	precoordinated int,
	measurement int,
	not_value int,
	pct_usable_consets numeric,
	value_records int,
	bad_unit int,
	bad_range int,
	missing_values int,
	no_spread int,
	outliers int,
	pct_usable_valsets numeric
);

create table if not exists __schema__.special_conditions (
	partner varchar(20),
	critique varchar(10),
	records int,
	record_perc numeric
);
