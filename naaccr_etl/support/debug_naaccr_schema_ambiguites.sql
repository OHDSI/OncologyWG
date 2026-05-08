--ICDO Codes participating in more than one NAACCR schema
SELECT c1.concept_id, COUNT(*)
                        FROM concept c1 JOIN concept_relationship cr ON c1.concept_id = cr.concept_id_1 and vocabulary_id='ICDO3'
                                        JOIN concept c2              ON cr.concept_id_2 = c2.concept_id and relationship_id = 'ICDO to Schema'
                        GROUP BY c1.concept_id
                        HAVING count(*) > 1
