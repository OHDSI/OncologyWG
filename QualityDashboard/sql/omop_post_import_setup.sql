-- ============================================================
-- OMOP CDM Post-Import Setup Script
-- Ausführen nach jedem Vocabulary-Update (neues prodv5_YYYYMM Schema)
-- 
-- Verwendung:
--   export SCHEMA=prodv5_202602   (neues Schema einsetzen)
--   envsubst < omop_post_import_setup.sql | psql -U postgres -d omop
--
-- Oder direkt mit psql-Variable:
--   psql -U postgres -d omop -v schema=prodv5_202602 -f omop_post_import_setup.sql
-- ============================================================

-- Setzt :'schema' als Variable - Beispiel: prodv5_202602
-- Bei direktem Aufruf ohne Variable fällt es auf prodv5 zurück
\set ON_ERROR_STOP on

-- ============================================================
-- 1. INDIZES
-- Alle CONCURRENTLY - kein Table Lock, kein Downtime
-- ============================================================

-- concept
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_concept_id
    ON :"schema".concept(concept_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_concept_vocabulary
    ON :"schema".concept(vocabulary_id, domain_id, standard_concept);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_concept_class_vocab
    ON :"schema".concept(vocabulary_id, concept_class_id);

-- concept_ancestor
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ca_ancestor
    ON :"schema".concept_ancestor(ancestor_concept_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ca_descendant
    ON :"schema".concept_ancestor(descendant_concept_id);

-- concept_relationship
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cr_concept_id_1
    ON :"schema".concept_relationship(concept_id_1);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cr_concept_id_2
    ON :"schema".concept_relationship(concept_id_2);

-- ============================================================
-- 2. ANALYZE
-- Statistiken für den Query-Planner aktualisieren
-- Zwingend nach Bulk-Import und nach CREATE INDEX!
-- ============================================================

ANALYZE :"schema".concept;
ANALYZE :"schema".concept_ancestor;
ANALYZE :"schema".concept_relationship;

-- ============================================================
-- 3. ROLLE: christian
-- search_path auf neues Schema aktualisieren
-- Aktuelles Schema vorne einsetzen
-- ============================================================

-- Anpassen: neues Schema als erstes eintragen
-- ALTER ROLE christian SET search_path = christian, prodv5_202602, prodv5, public;

-- ============================================================
-- 4. PLANNER-EINSTELLUNGEN (einmalig, bleibt dauerhaft)
-- Verhindert, dass der Planner Nested Loop bei großen CTEs wählt
-- (Problem: Planner schätzt 15 Zeilen, tatsächlich 154.000)
-- ============================================================

-- Nur beim ersten Mal nötig - bereits gesetzt:
-- ALTER ROLE christian SET enable_nestloop = off;
-- ALTER ROLE postgres  SET enable_nestloop = off;

-- Zum Prüfen ob bereits gesetzt:
SELECT rolname, rolconfig
FROM pg_roles
WHERE rolname IN ('christian', 'postgres');
