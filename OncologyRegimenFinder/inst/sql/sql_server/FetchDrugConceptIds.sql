SELECT distinct concept_id_2 FROM @cdmDatabaseSchema.concept_relationship
                    WHERE relationship_id IN (
                      'Has AB-drug cjgt Rx',
                      'Has cytotox chemo Rx',
                      'Has endocrine tx Rx',
                      'Has immunotherapy Rx',
                      'Has pept-drg cjg Rx',
                      'Has radiocjgt Rx',
                      'Has radiotherapy Rx',
                      'Has targeted tx Rx',
                      'Has antineopl Rx',
                      'Has immunosuppr Rx'
                    ) AND concept_id_2 NOT IN (
SELECT distinct ancestor_concept_id FROM
      @cdmDatabaseSchema.concept_ancestor
 JOIN (SELECT descendant_concept_id FROM
        @cdmDatabaseSchema.concept_ancestor
                    -- exclude drugs
        WHERE ancestor_concept_id IN (
         35803413, -- supportive
          @commentSteroids 21602722, 1506270, 1518254, 1550557 -- corticosteroids
          21602796, -- ATC 2nd antibiotics
          21603812, 1548195, -- ATC 2nd - endocrine therapy
          745466, -- valproate
          740910 --phenytoin

                      )
                    ) descendants_to_exclude
ON concept_ancestor.descendant_concept_id = descendants_to_exclude.descendant_concept_id
JOIN    @cdmDatabaseSchema.concept
ON concept.concept_id = concept_ancestor.ancestor_concept_id AND
concept_class_id = 'Ingredient'
                    )



