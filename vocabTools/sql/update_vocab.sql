-- Create or replace the update_vocabulary function
CREATE OR REPLACE FUNCTION public.update_vocabulary() RETURNS void AS $$
	BEGIN
		-- TRUNCATE and COPY for DRUG_STRENGTH
		TRUNCATE TABLE DRUG_STRENGTH;
		COPY DRUG_STRENGTH 
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\DRUG_STRENGTH.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for CONCEPT
		TRUNCATE TABLE CONCEPT;
		COPY CONCEPT 
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\CONCEPT.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			QUOTE E'\b',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for CONCEPT_RELATIONSHIP
		TRUNCATE TABLE CONCEPT_RELATIONSHIP;
		COPY CONCEPT_RELATIONSHIP
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\CONCEPT_RELATIONSHIP.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for CONCEPT_ANCESTOR
		TRUNCATE TABLE CONCEPT_ANCESTOR;
		COPY CONCEPT_ANCESTOR
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\CONCEPT_ANCESTOR.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for CONCEPT_SYNONYM
		TRUNCATE TABLE CONCEPT_SYNONYM;
		COPY CONCEPT_SYNONYM
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\CONCEPT_SYNONYM.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			QUOTE E'\b',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for VOCABULARY
		TRUNCATE TABLE VOCABULARY;
		COPY VOCABULARY
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\VOCABULARY.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for RELATIONSHIP
		TRUNCATE TABLE RELATIONSHIP;
		COPY RELATIONSHIP
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\RELATIONSHIP.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for CONCEPT_CLASS
		TRUNCATE TABLE CONCEPT_CLASS;
		COPY CONCEPT_CLASS
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\CONCEPT_CLASS.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
		-- TRUNCATE and COPY for DOMAIN
		TRUNCATE TABLE DOMAIN;
		COPY DOMAIN 
		FROM 'C:\Users\Public\Documents\oncologyVocab\vocab\DOMAIN.csv'
		WITH (
			FORMAT CSV,
			HEADER true,
			DELIMITER E'\t',
			NULL '',
			ENCODING 'utf-8'
		);
	END;
$$ LANGUAGE plpgsql;

SET search_path TO prod;
select public.update_vocabulary();

SET search_path TO dev;
select public.update_vocabulary();

SET search_path TO gisdev;
select public.update_vocabulary();