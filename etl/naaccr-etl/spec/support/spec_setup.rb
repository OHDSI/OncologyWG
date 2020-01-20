module NaaccrEtl
  module SpecSetup
    def self.teardown
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE naaccr_data_points CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE person CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_occurrence CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE measurement CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE observation CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE episode CASCADE;')
      ActiveRecord::Base.connection.execute('TRUNCATE TABLE fact_relationship CASCADE;')
    end

    def self.standard_concept(options={})
      Concept.where('c2.vocabulary_id = ? AND c2.concept_code = ?', options[:vocabulary_id], options[:concept_code]).joins("JOIN concept_relationship ON concept.concept_id = concept_relationship.concept_id_2 AND concept_relationship.relationship_id = 'Maps to' JOIN concept c2 ON concept_relationship.concept_id_1 = c2.concept_id").first
    end

    def self.concept(options={})
      Concept.where(vocabulary_id: options[:vocabulary_id], concept_code: options[:concept_code]).first
    end

    def self.naaccr_variable_concept(options={})
      Concept.where(concept_class_id: 'NAACCR Variable', concept_code: options[:concept_code]).first
    end

    def self.naaccr_value_concept(options={})
      Concept.where(concept_class_id: 'NAACCR Value', concept_code: options[:concept_code]).first
    end

    def self.unit_concept(concept_id)
      Concept.where('c2.concept_id = ?', concept_id).joins("JOIN concept_relationship ON concept.concept_id = concept_relationship.concept_id_2 AND concept_relationship.relationship_id = 'Has unit' JOIN concept c2 ON concept_relationship.concept_id_1 = c2.concept_id").first
    end

    def self.concept_numerics(concept_id)
      ConceptNumeric.where(concept_id: concept_id)
    end
  end
end