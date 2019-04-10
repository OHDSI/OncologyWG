SELECT  cs2.concept_code
      , regexp_replace ( cs2.concept_Name , '\|.*', '')
      , cs.*
FROM concept_stage cs           JOIN concept_relationship_stage crs ON cs.concept_code = crs.concept_code_1
                                JOIN concept_stage cs2              ON cs2.concept_code = crs.concept_code_2
WHERE cs.concept_code = '764';




SELECT DISTINCT   value_description
                , value_code
FROM schema_table
WHERE naaccr_item ='764'



SELECT DISTINCT   a.concept_code_2                            AS icdo_code
                , a.concept_code_1                            AS schema_id
                , regexp_replace (ac.concept_code, '.*@', '') AS naacr_item
                ,  ac.concept_name                            AS question_name
FROM concept_relationship_stage a JOIN concept_relationship_stage x ON x.concept_code_1 = a.concept_code_1 and x.relationship_id = 'Schema to Variable'
                                  JOIN concept_stage ac             ON ac.concept_code = x.concept_code_2 and ac.concept_class_id ='NAACCR Variable'
WHERE a.relationship_id = 'Schema to ICDO'



SELECT    cs.concept_name
        , cs.domain_id
        , cs.concept_class_id
        , cs.concept_code
        , crs.relationship_id
        , cs2.concept_name
        , cs2.domain_id
        , cs2.concept_class_id
        , cs2.concept_code
FROM concept_stage cs           JOIN concept_relationship_stage crs ON cs.concept_code = crs.concept_code_1
                                JOIN concept_stage cs2              ON cs2.concept_code = crs.concept_code_2
WHERE cs.concept_class_id = 'NAACCR Variable'
ORDER BY cs.concept_code, cs2.concept_code


SELECT    cs.concept_name
        , cs.domain_id
        , cs.concept_class_id
        , cs.concept_code
        , crs.relationship_id
        , cs2.concept_name
        , cs2.domain_id
        , cs2.concept_class_id
        , cs2.concept_code
FROM concept_stage cs           JOIN concept_relationship_stage crs ON cs.concept_code = crs.concept_code_1
                                JOIN concept_stage cs2              ON cs2.concept_code = crs.concept_code_2
WHERE cs.concept_class_id = 'NAACCR Variable'
--AND cs.concept_code = '764'
ORDER BY cs.concept_code, cs2.concept_code


SELECT DISTINCT   value_description
                , value_code
FROM schema_table
WHERE naaccr_item ='764'

"Regional by direct extension only
- Adjacent connective tissue(s)
- Adjacent organ(s)/structure(s)
- Regional extension, NOS"


"Regional by direct extension only
- All sites
    + Bladder neck
- Urethra
    + Corpus cavernosum
    + Corpus spongiosum
    + Periurethral muscle (sphincter muscle)
    + Vagina (anterior, NOS)
- Prostatic urethra
    + Periprostatic fat (beyond prostate capsule)
    + Prostate (prostatic stroma)
    + Prostatic ducts"


SELECT  cs2.concept_code
      , regexp_replace ( cs2.concept_Name , '\|.*', '')
FROM concept_stage cs           JOIN concept_relationship_stage crs ON cs.concept_code = crs.concept_code_1
                                JOIN concept_stage cs2              ON cs2.concept_code = crs.concept_code_2
WHERE cs.concept_code = '764';

