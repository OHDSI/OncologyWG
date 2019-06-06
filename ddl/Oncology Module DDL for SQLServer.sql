-- SQL SERVER

-- episode
CREATE TABLE [dbo].[episode](
	[episode_id] [bigint] NOT NULL,
	[person_id] [bigint] NOT NULL,
	[episode_start_datetime] [datetime2](7) NOT NULL,
	[episode_end_datetime] [datetime2](7) NOT NULL,
	[episode_concept_id] [bigint] NOT NULL,
	[episode_parent_id] [bigint] NULL,
	[episode_number] [bigint] NULL,
	[episode_object_concept_id] [bigint] NOT NULL,
	[episode_type_concept_id] [bigint] NOT NULL,
	[episode_source_value] [varchar](50) NULL,
	[episode_source_concept_id] [bigint] NULL
) ON [PRIMARY]

-- episode_event
CREATE TABLE [dbo].[episode_event](
	[episode_id] [bigint] NOT NULL,
	[event_id] [bigint] NOT NULL,
	[event_field_concept_id] [bigint] NOT NULL
) ON [PRIMARY]

-- measurement
CREATE TABLE [dbo].[measurement](
	[measurement_id] [bigint] NOT NULL,
	[person_id] [bigint] NOT NULL,
	[measurement_concept_id] [bigint] NOT NULL,
	[measurement_date] [date] NULL,
	[measurement_datetime] [datetime2](7) NOT NULL,
	[measurement_time] [varchar](10) NULL,
	[measurement_type_concept_id] [bigint] NOT NULL,
	[operator_concept_id] [bigint] NULL,
	[value_as_number] [float] NULL,
	[value_as_concept_id] [bigint] NULL,
	[unit_concept_id] [bigint] NULL,
	[range_low] [float] NULL,
	[range_high] [float] NULL,
	[provider_id] [bigint] NULL,
	[visit_occurrence_id] [bigint] NULL,
	[visit_detail_id] [bigint] NULL,
	[measurement_source_value] [varchar](50) NULL,
	[measurement_source_concept_id] [bigint] NOT NULL,
	[unit_source_value] [varchar](50) NULL,
	[value_source_value] [varchar](50) NULL,
	[modifier_of_event_id] [bigint] NULL,
	[modifier_of_field_concept_id] [bigint] NULL
) ON [PRIMARY]

-- Constraints

	--pk
	ALTER TABLE episode_event
    ADD CONSTRAINT episode_event_pk PRIMARY KEY (episode_id, event_id, event_field_concept_id);

	ALTER TABLE episode
	ADD CONSTRAINT episode_pk PRIMARY KEY NONCLUSTERED ( episode_id ) ;


	--fk
	ALTER TABLE measurement
    ADD CONSTRAINT modifier_of_field_concept_id_fk FOREIGN KEY (modifier_of_field_concept_id)
    REFERENCES concept (concept_id);

	ALTER TABLE episode
    ADD CONSTRAINT person_id_fk FOREIGN KEY (person_id)
    REFERENCES person (person_id);
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_concept_id_fk FOREIGN KEY (episode_concept_id)
    REFERENCES concept (concept_id);

	ALTER TABLE episode
    ADD CONSTRAINT episode_object_concept_id_fk FOREIGN KEY (episode_object_concept_id)
    REFERENCES concept (concept_id);
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_parent_id_fk FOREIGN KEY (episode_parent_id)
    REFERENCES episode (episode_id);
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_source_concept_id_fk FOREIGN KEY (episode_source_concept_id)
    REFERENCES concept (concept_id);
	
	ALTER TABLE episode
    ADD CONSTRAINT episode_type_concept_id_fk FOREIGN KEY (episode_type_concept_id)
    REFERENCES concept (concept_id);

	ALTER TABLE episode_event
    ADD CONSTRAINT event_field_concept_id_fk FOREIGN KEY (event_field_concept_id)
    REFERENCES concept (concept_id);




