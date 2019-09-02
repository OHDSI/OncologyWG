DO $_$
DECLARE
z int4;
BEGIN
	--create sequence for concept codes
	select coalesce(max(replace(c.concept_code, 'CDM','')::int4),0)+1 into z from concept c where c.vocabulary_id='CDM' and c.concept_code like 'CDM%' and c.concept_class_id<>'CDM';
	drop sequence if exists cdm_seq;
	execute 'create sequence cdm_seq increment by 1 start with ' || z || ' no cycle cache 20';

	--create sequence for concept id's

	drop sequence if exists v5_concept;
	execute 'create sequence v5_concept increment by 1 start with 1000000000 cache 20'; 

	--create new Field concept='modifier_of_event_id' for existing table 'measurement'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'measurement.modifier_of_event_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='modifier_of_field_concept_id' for existing table 'measurement'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'measurement.modifier_of_field_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Table concept='episode'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Table' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.person_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.person_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_start_datetime'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_start_datetime' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_end_datetime'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_end_datetime' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_parent_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_parent_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_number'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_number' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_object_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_object_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_type_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_type_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_source_value'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_source_value' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_source_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode.episode_source_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Table concept='episode_event'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode_event' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Table' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.episode_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode_event.episode_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.event_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode_event.event_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.event_table_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select nextval('v5_concept') as concept_id,
		'episode_event.event_table_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM'||nextval('cdm_seq') as concept_code,
		current_date as valid_start_date,
		to_date ('20991231', 'yyyymmdd') as valid_end_date,
		null as invalid_reason;

	--clearing
	drop sequence cdm_seq;
	drop sequence v5_concept;
END $_$;
