require 'rails_helper'
describe NaaccrEtl do
  before(:each) do
    @person = FactoryBot.create(:person)
    @legacy = false
  end

  after(:each) do
    NaaccrEtl::SpecSetup.teardown
  end

  describe "For an 'ICDO Condition' that maps to itself" do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8140/3-C61.9'
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value:  @diagnosis_date \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site:  @histology_site \
      )
      @condition_concept = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it "Creates an entry in the CONDITION_OCCURRENCE table", focus: false do
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(condition_occurrence.condition_concept_id).to eq(@condition_concept.concept_id)
      expect(condition_occurrence.person_id).to eq(@person.person_id)
      expect(condition_occurrence.condition_start_date).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(condition_occurrence.condition_source_value).to eq(@histology_site)
      expect(condition_occurrence.condition_source_concept_id).to eq(@condition_concept.concept_id)
    end

    it "Creates an entry in the EPISODE table", focus: false do
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(episode.person_id).to eq(@person.person_id)
      expect(episode.episode_concept_id).to eq(32528) #32528='Disease First Occurrence'
      expect(episode.episode_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(episode.episode_end_datetime).to be_nil
      expect(episode.episode_object_concept_id).to eq(@condition_concept.concept_id)
      expect(episode.episode_type_concept_id).to eq(32546)
      expect(episode.episode_source_value).to eq(@histology_site)
      expect(episode.episode_source_concept_id).to eq(@condition_concept.concept_id)
    end
  end

  describe "For an 'ICDO Condition' that maps to a SNOMED concept" do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8560/3-C54.1'
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value:  @diagnosis_date \
        , histology: '8560/3' \
        , site: 'C54.1' \
        , histology_site:  @histology_site \
      )
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      @condition_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it "Creates an entry in the CONDITION_OCCURRENCE table", focus: false do
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(condition_occurrence.condition_concept_id).to eq(@condition_concept.concept_id)
      expect(condition_occurrence.person_id).to eq(@person.person_id)
      expect(condition_occurrence.condition_start_date).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(condition_occurrence.condition_source_value).to eq(@histology_site)
      expect(condition_occurrence.condition_source_concept_id).to eq(@condition_source_concept.concept_id)
    end

    it "Creates an entry in the EPISODE table ", focus: false do
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(episode.person_id).to eq(@person.person_id)
      expect(episode.episode_concept_id).to eq(32528) #32528='Disease First Occurrence'
      expect(episode.episode_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(episode.episode_end_datetime).to be_nil
      expect(episode.episode_object_concept_id).to eq(@condition_concept.concept_id)
      expect(episode.episode_type_concept_id).to eq(32546)
      expect(episode.episode_source_value).to eq(@histology_site)
      expect(episode.episode_source_concept_id).to eq(@condition_source_concept.concept_id)
    end
  end

  describe 'Creating entries in MEASUREMENT table for a standard categorical schema-independent diagnosis modifier' do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8140/3-C61.9'
      @naaccr_item_number = '1182'          #Lymph-vascular Invasion
      @naaccr_item_value = '1'              #Lymph-vascular Invasion Present/Identified

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )
      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number}@#{@naaccr_item_value}")
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE' do
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
      measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
      expect(measurement.person_id).to eq(@person.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
    end

    it 'pointing to EPISODE' do
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
      measurement = Measurement.where(modifier_of_field_concept_id: 1000000003).first
      expect(measurement.person_id).to eq(@person.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
    end
  end

  describe 'Ambiguous ICDO3 codes participating in multiple NAACCR schemas' do
    describe 'Creating entries in MEASUREMENT table for a standard categorical schema-independent diagnosis modifier' do
      before(:each) do
        @diagnosis_date = '20170630'
        @histology_site = '8013/3-C16.1'
        @naaccr_item_number = '1182'          #Lymph-vascular Invasion
        @naaccr_item_value = '1'              #Lymph-vascular Invasion Present/Identified

        FactoryBot.create(:naaccr_data_point \
          , person_id: @person.person_id \
          , record_id: '1' \
          , naaccr_item_number: '390' \
          , naaccr_item_value: @diagnosis_date \
          , histology: '8013/3' \
          , site: 'C16.1' \
          , histology_site: @histology_site \
        )

        FactoryBot.create(:naaccr_data_point \
          , person_id: @person.person_id \
          , record_id: '1' \
          , naaccr_item_number: @naaccr_item_number \
          , naaccr_item_value: @naaccr_item_value  \
          , histology: '8013/3' \
          , site: 'C16.1' \
          , histology_site: @histology_site \
        )
        @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
        @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
        @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number}@#{@naaccr_item_value}")
        @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
        NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
      end

      it 'pointing to CONDITION_OCCURRENCE', focus: true do
        expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
        measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
        expect(measurement.person_id).to eq(@person.person_id)
        expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
        expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_time).to be_nil
        expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
        expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement.value_source_value).to eq(@naaccr_item_value)
        expect(ConditionOccurrence.count).to eq(1)
        condition_occurrence = ConditionOccurrence.first
        expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
        expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
      end

      it 'pointing to EPISODE' do
        expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
        measurement = Measurement.where(modifier_of_field_concept_id: 1000000003).first
        expect(measurement.person_id).to eq(@person.person_id)
        expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
        expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_time).to be_nil
        expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
        expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement.value_source_value).to eq(@naaccr_item_value)
        expect(Episode.count).to eq(1)
        episode = Episode.first
        expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
        expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
      end
    end
  end
end