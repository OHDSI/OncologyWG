-- Create or replace the populate_vocabulary function
CREATE OR REPLACE FUNCTION public.populate_vocabulary(base_path text) RETURNS void AS $$
	BEGIN
		-- TRUNCATE and COPY for DRUG_STRENGTH
		EXECUTE format('TRUNCATE TABLE DRUG_STRENGTH;
		COPY DRUG_STRENGTH 
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for CONCEPT
		EXECUTE format('TRUNCATE TABLE CONCEPT;
		COPY CONCEPT 
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			QUOTE E''\b'',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for CONCEPT_RELATIONSHIP
		EXECUTE format('TRUNCATE TABLE CONCEPT_RELATIONSHIP;
		COPY CONCEPT_RELATIONSHIP
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for CONCEPT_ANCESTOR
		EXECUTE format('TRUNCATE TABLE CONCEPT_ANCESTOR;
		COPY CONCEPT_ANCESTOR
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for CONCEPT_SYNONYM
		EXECUTE format('TRUNCATE TABLE CONCEPT_SYNONYM;
		COPY CONCEPT_SYNONYM
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			QUOTE E''\b'',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for VOCABULARY
		EXECUTE format('TRUNCATE TABLE VOCABULARY;
		COPY VOCABULARY
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for RELATIONSHIP
		EXECUTE format('TRUNCATE TABLE RELATIONSHIP;
		COPY RELATIONSHIP
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for CONCEPT_CLASS
		EXECUTE format('TRUNCATE TABLE CONCEPT_CLASS;
		COPY CONCEPT_CLASS
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
		-- TRUNCATE and COPY for DOMAIN
		EXECUTE format('TRUNCATE TABLE DOMAIN;
		COPY DOMAIN 
		FROM %L
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E''\t'',
			NULL '''',
			ENCODING ''utf-8''
		);', base_path || 'DRUG_STRENGTH.csv');
	END;
$$ LANGUAGE plpgsql;

