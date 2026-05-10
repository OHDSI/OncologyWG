DECLARE @z bigint;
DECLARE @sql varchar(1000);

BEGIN
	--create sequence for concept codes
	select @z = coalesce(max(cast(replace(c.concept_code, 'CDM','') as bigint)),0)+1 from concept c where c.vocabulary_id='CDM' and c.concept_code like 'CDM%' and c.concept_class_id<>'CDM' and 0=1;
	if object_id(N'cdm_seq') is not null
  	  drop sequence cdm_seq;
	set @sql = 'create sequence cdm_seq as bigint start with ' + convert(varchar(20), @z) + ' increment by 1 no cycle cache 20;';
	execute (@sql);

	--create sequence for concept id's
	if object_id(N'v5_concept') is not null
  	  drop sequence v5_concept;	
	execute ('create sequence v5_concept as bigint start with 1000000000 increment by 1 no cycle cache 20;');

	--create new Field concept='modifier_of_event_id' for existing table 'measurement'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'measurement.modifier_of_event_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='modifier_of_field_concept_id' for existing table 'measurement'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'measurement.modifier_of_field_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Table concept='episode'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Table' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.person_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.person_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_start_datetime'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_start_datetime' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_end_datetime'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_end_datetime' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_parent_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_parent_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_number'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_number' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_object_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_object_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_type_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_type_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_source_value'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_source_value' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode.episode_source_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode.episode_source_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Table concept='episode_event'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode_event' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Table' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.episode_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode_event.episode_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.event_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode_event.event_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--create new Field concept='episode_event.event_table_concept_id'
	insert into concept (concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
	select next value for v5_concept as concept_id,
		'episode_event.event_table_concept_id' as concept_name,
		'Metadata' as domain_id,
		'CDM' as vocabulary_id,
		'Field' as concept_class_id,
		'S' as standard_concept,
		'CDM' + convert(varchar(20), (next value for cdm_seq)) as concept_code,
		convert(date, getdate()) as valid_start_date,
		convert (DATETIME, '20991231', 112) as valid_end_date,
		null as invalid_reason;

	--clearing
	drop sequence cdm_seq;
	drop sequence v5_concept;

END
