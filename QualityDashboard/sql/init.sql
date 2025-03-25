create schema if not exists __schema__ Authorization postgres;

create table if not exists __schema__.general (
    partner varchar(10),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );
  
create table if not exists __schema__.genomic (
    partner varchar(10),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );

create table if not exists __schema__.episodes (
    partner varchar(10),
    domain varchar(1),
    source bigint,
    standard int,
    cnt int
  );

create table if not exists __schema__.patient (
    partner varchar(10),
    cnt int
  );

create table if not exists __schema__.database_summary (
    partner varchar(10),
    size int,
    general bigint,
    genomic bigint,
    episodes bigint
  );

create table if not exists __schema__.individual_concept_report (
    partner varchar(10),
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
    partner varchar(10),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists __schema__.source_summary_report (
    partner varchar(10),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists __schema__.mapping_summary_report (
    partner varchar(10),
    critique varchar(255),
    records bigint,
    "record_%" numeric
  );

create table if not exists __schema__.domain_weights (
    partner varchar(10),
    domain varchar(20),
    records bigint,
    "record_%" numeric
  );
  
create table if not exists __schema__.rolled_up_tumor_types (
    partner varchar(10),
    cancer_type varchar(30),
    records bigint,
    "record_%" numeric
  );  

create table if not exists __schema__.records_and_concepts_in_source_and_standard (
  partner varchar(10),
  size int,
  t_records bigint,
  records_patient numeric,
  t_source bigint,
  source_patient numeric,
  t_standard bigint,
  standard_patient numeric
);

create table if not exists __schema__.number_of_records_per_domain (
    partner varchar(10),
    domain varchar(20),
    records bigint,
    "records_%" numeric,
    concepts bigint,
    "concept_%" numeric
);

create table if not exists __schema__.number_of_records_per_vocabulary (
    partner varchar(10),
    domain varchar(20),
    vocabulary varchar(20),
    records bigint,
    "records_%" numeric,
    concepts bigint,
    "concept_%" numeric
);
  
create table if not exists __schema__.rolled_up_tumor_types_for_each_partner (
    partner varchar(10),
    cancer_type varchar(30),
    records bigint,
    "record_%" numeric
  );  

create table if not exists __schema__.count_existing_source_concepts (
    partner varchar(10),
    in_vocab varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concept_%" numeric
);

create table if not exists __schema__.standard_concepts_in_standard_fields (
    partner varchar(10),
    concept varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.domain_for_standard_concepts (
    partner varchar(10),
    domain varchar(10),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);

create table if not exists __schema__.standard_concept_report (
    partner varchar(10),
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
    partner varchar(10),
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
    partner varchar(10),
    source varchar(10),
    mapping varchar(20),
    records bigint,
    "record_%" numeric,
    concepts bigint,
    "concepts_%" numeric
);
