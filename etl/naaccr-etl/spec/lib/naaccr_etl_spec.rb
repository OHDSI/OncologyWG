require 'rails_helper'
describe NaaccrEtl do
  before(:each) do
    NaaccrEtl::SpecSetup.teardown
    @person_1 = FactoryBot.create(:person)
    @person_2 = FactoryBot.create(:person)
    @legacy = false
  end

  after(:each) do
    # NaaccrEtl::SpecSetup.teardown
  end

  describe "For an 'ICDO Condition' that maps to itself" do
    before(:each) do
      @diagnosis_date = '19981022'
      @histology_site = '8140/3-C61.9'
      #390=Date of Diagnosis
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
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

    it "creates an entry in the CONDITION_OCCURRENCE table", focus: false do
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(condition_occurrence.condition_concept_id).to eq(@condition_concept.concept_id)
      expect(condition_occurrence.person_id).to eq(@person_1.person_id)
      expect(condition_occurrence.condition_start_date).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(condition_occurrence.condition_source_value).to eq(@histology_site)
      expect(condition_occurrence.condition_source_concept_id).to eq(@condition_concept.concept_id)
    end

    it "creates an entry in the EPISODE table", focus: false do
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(episode.person_id).to eq(@person_1.person_id)
      expect(episode.episode_concept_id).to eq(32528) #32528='Disease First Occurrence'
      expect(episode.episode_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(episode.episode_end_datetime).to be_nil
      expect(episode.episode_object_concept_id).to eq(@condition_concept.concept_id)
      expect(episode.episode_type_concept_id).to eq(32546)
      expect(episode.episode_source_value).to eq(@histology_site)
      expect(episode.episode_source_concept_id).to eq(@condition_concept.concept_id)
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      #1147127 = ‘condition_occurrence.condition_occurrence_id’ concept
      expect(EpisodeEvent.where(episode_id: episode.episode_id, event_id: condition_occurrence.condition_occurrence_id, episode_event_field_concept_id: 1147127).count).to eq(1)
    end
  end

  describe "For an 'ICDO Condition' that maps to a SNOMED concept" do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8560/3-C54.1'
      #390=Date of Diagnosis
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
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

    it "creates an entry in the CONDITION_OCCURRENCE table", focus: false do
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(condition_occurrence.condition_concept_id).to eq(@condition_concept.concept_id)
      expect(condition_occurrence.person_id).to eq(@person_1.person_id)
      expect(condition_occurrence.condition_start_date).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_start_datetime).to eq(Date.parse(@diagnosis_date))
      expect(condition_occurrence.condition_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(condition_occurrence.condition_source_value).to eq(@histology_site)
      expect(condition_occurrence.condition_source_concept_id).to eq(@condition_source_concept.concept_id)
    end

    it "creates an entry in the EPISODE table ", focus: false do
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(episode.person_id).to eq(@person_1.person_id)
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

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
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
      expect(measurement.person_id).to eq(@person_1.person_id)
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
      expect(measurement.person_id).to eq(@person_1.person_id)
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

  describe 'Creating entries in MEASUREMENT table for a non-standard categorical schema-independent diagnosis modifier' do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology = '8140/3'
      @site = 'C61.9'
      @histology_site = "#{@histology}-#{@site}"
      @naaccr_item_number = '1011'          #AJCC TNM Path T
      @naaccr_item_number_standard = '880'
      @naaccr_item_value = 'p2'             #Lymph-vascular Invasion Present/Identified

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )
      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_standard)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_standard)
      @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_standard}@#{@naaccr_item_value}")
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
      measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number_standard)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
    end

    it 'pointing to EPISODE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
      measurement = Measurement.where(modifier_of_field_concept_id: 1000000003).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number_standard)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
    end
  end

  describe 'Creating entries in MEASUREMENT table for a numeric schema-independent diagnosis modifier for a numeric value' do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8140/3-C61.9'
      @naaccr_item_number = '754'           #Tumor Size Pathologic
      @naaccr_item_value = '002'            #2

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )
      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @unit_concept = NaaccrEtl::SpecSetup.unit_concept(@measurement_concept.concept_id)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)

      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
      measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to be_nil
      expect(measurement.value_as_number).to eq(@naaccr_item_value.to_f)
      expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
    end

    it 'pointing to EPISODE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
      measurement = Measurement.where(modifier_of_field_concept_id: 1000000003).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_number).to eq(@naaccr_item_value.to_f)
      expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
    end
  end

  describe 'Creating entries in MEASUREMENT table for a numeric schema-independent diagnosis modifier for a categorical value' do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology_site = '8140/3-C61.9'
      @naaccr_item_number = '754'           #Tumor Size Pathologic
      @naaccr_item_value = '990'            #Microscopic focus or foci only and no size of focus is given

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )
      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @unit_concept = NaaccrEtl::SpecSetup.unit_concept(@measurement_concept.concept_id)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number}@#{@naaccr_item_value}")
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
      measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.value_as_number).to be_nil
      expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first
      expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
    end

    it 'pointing to EPISODE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
      measurement = Measurement.where(modifier_of_field_concept_id: 1000000003).first
      expect(measurement.person_id).to eq(@person_1.person_id)
      expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
      expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_time).to be_nil
      expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
      expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
      expect(measurement.value_as_number).to be_nil
      expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
      expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement.value_source_value).to eq(@naaccr_item_value)
      expect(Episode.count).to eq(1)
      episode = Episode.first
      expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
      expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
    end
  end

  describe 'Creating entries in MEASUREMENT table for a numeric schema-independent diagnosis modifier for a numeric value derived from the CONCEPT_NUMERIC table' do
    before(:each) do
      @diagnosis_date = '20170630'
      @histology = '8507/3'
      @site = 'C50.9'
      @histology_site = "#{@histology}-#{@site}"
      @naaccr_item_number = '3914'          #Progesterone Receptor Percent Positive or Range
      @naaccr_item_value = 'R50'            #Stated as 41-50%

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: @histology_site \
      )
      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @unit_concept = NaaccrEtl::SpecSetup.unit_concept(@measurement_concept.concept_id)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number}@#{@naaccr_item_value}")
      @concept_numerics = NaaccrEtl::SpecSetup.concept_numerics(@measurement_value_as_concept.concept_id)
      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(@concept_numerics.size).to eq(2)
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(@concept_numerics.size)       #1147127 = 'condition_occurrence.condition_occurrence_id'
      expect(ConditionOccurrence.count).to eq(1)
      condition_occurrence = ConditionOccurrence.first

      @concept_numerics.each do |concept_numeric|
        measurement = Measurement.where(modifier_of_field_concept_id: 1147127, value_as_number: concept_numeric.value_as_number).first
        expect(measurement.person_id).to eq(@person_1.person_id)
        expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
        expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_time).to be_nil
        expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement.operator_concept_id).to eq(concept_numeric.operator_concept_id)
        expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
        expect(measurement.value_as_number).to eq(concept_numeric.value_as_number)
        expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
        expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement.value_source_value).to eq(@naaccr_item_value)
        expect(measurement.modifier_of_event_id).to eq(condition_occurrence.condition_occurrence_id)
        expect(measurement.modifier_of_field_concept_id).to eq(1147127) #‘condition_occurrence.condition_occurrence_id’ concept
      end
    end

    it 'pointing to EPISODE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(2)
      expect(Episode.count).to eq(1)
      episode = Episode.first

      @concept_numerics.each do |concept_numeric|
        measurement = Measurement.where(modifier_of_field_concept_id: 1000000003, value_as_number: concept_numeric.value_as_number).first
        expect(measurement.person_id).to eq(@person_1.person_id)
        expect(measurement.measurement_concept_id).to eq(@measurement_concept.concept_id)
        expect(measurement.measurement_date).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_time).to be_nil
        expect(measurement.measurement_datetime).to eq(Date.parse(@diagnosis_date))
        expect(measurement.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement.operator_concept_id).to eq(concept_numeric.operator_concept_id)
        expect(measurement.value_as_concept_id).to eq(@measurement_value_as_concept.concept_id)
        expect(measurement.value_as_number).to eq(concept_numeric.value_as_number)
        expect(measurement.unit_concept_id).to eq(@unit_concept.concept_id)
        expect(measurement.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement.value_source_value).to eq(@naaccr_item_value)
        expect(measurement.modifier_of_event_id).to eq(episode.episode_id)
        expect(measurement.modifier_of_field_concept_id).to eq(1000000003) #‘‘episode.episode_id’ concept
      end
    end
  end

  describe 'Creating entries in MEASUREMENT table for a standard categorical schema-dependent NAACCR variable diagnosis modifier' do
    before(:each) do
      @diagnosis_date_1 = '20170630'
      @histology_1 = '9421/3'
      @site_1 = 'C71.3'
      @histology_site_1 = "#{@histology_1}-#{@site_1}"

      @diagnosis_date_2 = '20180630'
      @histology_2 = '8507/3'
      @site_2 = 'C50.8'
      @histology_site_2 = "#{@histology_2}-#{@site_2}"

      @naaccr_item_number = '2880'          #?

      @naaccr_schema_concept_code_1 = 'brain'
      @naaccr_item_value_1 = '020'            #"Grade II"

      @naaccr_schema_concept_code_2 = 'breast'
      @naaccr_item_value_2 = '020'            #"Negative/normal; within normal limits"

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date_1 \
        , histology: @histology_1  \
        , site: @site_1 \
        , histology_site: @histology_site_1 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value_1  \
        , histology: @histology_1 \
        , site: @site_1 \
        , histology_site: @histology_site_1 \
      )

      #390=Date of Diagnosis.
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date_2 \
        , histology: @histology_2  \
        , site: @site_2 \
        , histology_site: @histology_site_2 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value_2  \
        , histology: @histology_2 \
        , site: @site_2 \
        , histology_site: @histology_site_2 \
      )

      @measurement_concept_1 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}")
      concept_code = "#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}@#{@naaccr_item_value_1}"
      @measurement_value_as_concept_1 = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}@#{@naaccr_item_value_1}")
      @condition_concept_1 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site_1)

      @measurement_concept_2 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number}")
      @measurement_value_as_concept_2 = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number}@#{@naaccr_item_value_2}")
      @condition_concept_2 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site_2)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(ConditionOccurrence.count).to eq(2)
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(2) #1147127 = 'condition_occurrence.condition_occurrence_id'

      condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept_1.concept_id).first
      #1147127 = 'condition_occurrence.condition_occurrence_id'

      measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id, measurement_concept_id: @measurement_concept_1.concept_id, value_as_concept_id: @measurement_value_as_concept_1.concept_id).first
      expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_time).to be_nil
      expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_1.measurement_source_value).to eq("#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}")
      expect(measurement_1.measurement_source_concept_id).to eq(@measurement_concept_1.concept_id)
      expect(measurement_1.value_source_value).to eq(@naaccr_item_value_1)

      condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept_2.concept_id).first
      measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept_2.concept_id, value_as_concept_id: @measurement_value_as_concept_2.concept_id).first
      expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_time).to be_nil
      expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_2.measurement_source_value).to eq("#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number}")
      expect(measurement_2.measurement_source_concept_id).to eq(@measurement_concept_2.concept_id)
      expect(measurement_2.value_source_value).to eq(@naaccr_item_value_2)
    end

    it 'pointing to EPISODE', focus: false do
      expect(ConditionOccurrence.count).to eq(2)
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(2) #1000000003 = ‘episode.episode_id’ concept

      condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept_1.concept_id).first
      #1000000003 = ‘episode.episode_id’ concept
      measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_concept_1.concept_id, value_as_concept_id: @measurement_value_as_concept_1.concept_id).first
      expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_time).to be_nil
      expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_1.measurement_source_value).to eq("#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}")
      expect(measurement_1.measurement_source_concept_id).to eq(@measurement_concept_1.concept_id)
      expect(measurement_1.value_source_value).to eq(@naaccr_item_value_1)

      condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept_2.concept_id).first
      measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept_2.concept_id, value_as_concept_id: @measurement_value_as_concept_2.concept_id).first
      expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_time).to be_nil
      expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_2.measurement_source_value).to eq("#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number}")
      expect(measurement_2.measurement_source_concept_id).to eq(@measurement_concept_2.concept_id)
      expect(measurement_2.value_source_value).to eq(@naaccr_item_value_2)
    end
  end

  describe 'Creating entries in MEASUREMENT table for a standard categorical schema-dependent NAACCR value diagnosis modifier' do
    before(:each) do
      # @histology = '8070/2'
      # @site = 'C00.3'
      # @histology_site = "#{@histology}-#{@site}"
      # @diagnosis_date_1 = '20170630'
      # @diagnosis_date_2 = '20180630'
      #
      # @naaccr_item_number = '772'               #EOD Primary Tumor
      # @naaccr_item_value = '200'                #200
      # @naaccr_schema_concept_code = 'lip_upper'

      @histology = '9180/3'
      @site = 'C67.7'
      @histology_site = "#{@histology}-#{@site}"
      @diagnosis_date_1 = '20170630'
      @diagnosis_date_2 = '20180630'

      @naaccr_item_number = '772'               #EOD Primary Tumor
      @naaccr_item_value = '200'                #200
      @naaccr_schema_concept_code = 'bladder'

      #Person 1
      #390=Date of Diagnosis
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date_1 \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      #Person 2
      #390=Date of Diagnosis
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: @diagnosis_date_2 \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: @naaccr_item_number \
        , naaccr_item_value: @naaccr_item_value  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
      @measurement_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_schema_concept_code}@#{@naaccr_item_number}@#{@naaccr_item_value}")

      @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to CONDITION_OCCURRENCE', focus: false do
      expect(ConditionOccurrence.count).to eq(2)
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(2) #1147127 = 'condition_occurrence.condition_occurrence_id'

      condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept.concept_id).first
      #1147127 = 'condition_occurrence.condition_occurrence_id'
      measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept.concept_id).first
      expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_time).to be_nil
      expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_1.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement_1.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement_1.value_source_value).to eq(@naaccr_item_value)

      condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept.concept_id).first
      measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept.concept_id).first
      expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_time).to be_nil
      expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_2.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement_2.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement_2.value_source_value).to eq(@naaccr_item_value)
    end

    it 'pointing to EPISODE', focus: false do
      expect(ConditionOccurrence.count).to eq(2)
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(2) #1000000003 = ‘episode.episode_id’ concept

      condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept.concept_id).first
      #1000000003 = ‘episode.episode_id’ concept
      measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept.concept_id).first
      expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_time).to be_nil
      expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
      expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_1.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement_1.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement_1.value_source_value).to eq(@naaccr_item_value)

      condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept.concept_id).first
      measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept.concept_id).first
      expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_time).to be_nil
      expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
      expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_2.measurement_source_value).to eq(@naaccr_item_number)
      expect(measurement_2.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
      expect(measurement_2.value_source_value).to eq(@naaccr_item_value)
    end
  end

  describe 'Ambiguous ICDO3 codes participating in multiple NAACCR schemas' do
    describe 'Creating entries in MEASUREMENT table for a standard categorical schema-independent diagnosis modifier' do
      before(:each) do
        @diagnosis_date = '20170630'
        @histology_site = '8013/3-C16.1'
        @naaccr_item_number = '1182'              #Lymph-vascular Invasion
        @naaccr_item_value = '1'                  #Lymph-vascular Invasion Present/Identified

        #390=Date of Diagnosis
        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_1.person_id \
          , record_id: '1' \
          , naaccr_item_number: '390' \
          , naaccr_item_value: @diagnosis_date \
          , histology: '8013/3' \
          , site: 'C16.1' \
          , histology_site: @histology_site \
        )

        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_1.person_id \
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

      it 'pointing to CONDITION_OCCURRENCE', focus: false do
        expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)       #1147127 = 'condition_occurrence.condition_occurrence_id'
        measurement = Measurement.where(modifier_of_field_concept_id: 1147127).first
        expect(measurement.person_id).to eq(@person_1.person_id)
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
        expect(measurement.person_id).to eq(@person_1.person_id)
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

    describe 'Creating entries in MEASUREMENT table for a standard categorical schema-dependent NAACCR value diagnosis modifier' do
      before(:each) do
        @histology = '8000/0'
        @site = 'C16.1'
        @histology_site = "#{@histology}-#{@site}"
        @diagnosis_date_1 = '20170630'
        @diagnosis_date_2 = '20180630'

        @naaccr_item_number = '772'               #EOD Primary Tumor
        @naaccr_item_value = '200'                #200

        @naaccr_item_number_discriminator = '2879'

        @naaccr_item_number_discriminator_1 = 'stomach@2879'              #Schema Discriminator: EsophagusGEJunction (EGJ)/Stomach
        @naaccr_schema_concept_code_1 = 'stomach'
        @naaccr_item_value_discriminator_1 = '030'                #030

        @naaccr_item_number_discriminator_2 = 'esophagus_gejunction@2879' #Schema Discriminator: EsophagusGEJunction (EGJ)/Stomach
        @naaccr_schema_concept_code_2 = 'esophagus_gejunction'
        @naaccr_item_value_discriminator_2 = '040'                #040

        #Person 1
        #390=Date of Diagnosis
        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_1.person_id \
          , record_id: '1' \
          , naaccr_item_number: '390' \
          , naaccr_item_value: @diagnosis_date_1 \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_1.person_id \
          , record_id: '1' \
          , naaccr_item_number: @naaccr_item_number \
          , naaccr_item_value: @naaccr_item_value  \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        #2879=CS SITE-SPECIFIC FACTOR25
        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_1.person_id \
          , record_id: '1' \
          , naaccr_item_number: @naaccr_item_number_discriminator  \
          , naaccr_item_value: @naaccr_item_value_discriminator_1  \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        #Person 2
        #390=Date of Diagnosis
        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_2.person_id \
          , record_id: '2' \
          , naaccr_item_number: '390' \
          , naaccr_item_value: @diagnosis_date_2 \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_2.person_id \
          , record_id: '2' \
          , naaccr_item_number: @naaccr_item_number \
          , naaccr_item_value: @naaccr_item_value  \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        #2879=CS SITE-SPECIFIC FACTOR25
        FactoryBot.create(:naaccr_data_point \
          , person_id: @person_2.person_id \
          , record_id: '2' \
          , naaccr_item_number: @naaccr_item_number_discriminator  \
          , naaccr_item_value: @naaccr_item_value_discriminator_2  \
          , histology: @histology \
          , site: @site \
          , histology_site: @histology_site \
        )

        @measurement_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)
        @measurement_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number)

        @measurement_discriminator_concept_1 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_discriminator_1)
        @measurement_discriminator_concept_2 =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_discriminator_2)

        @measurement_discriminator_source_concept_1 = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_discriminator_1)
        @measurement_discriminator_source_concept_2 = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_discriminator_2)

        @measurement_value_as_concept_1 = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number}@#{@naaccr_item_value}")
        @measurement_value_as_concept_2 = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number}@#{@naaccr_item_value}")

        @condition_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
        NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
      end

      it 'pointing to CONDITION_OCCURRENCE', focus: false do
        expect(ConditionOccurrence.count).to eq(2)
        expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(4) #1147127 = 'condition_occurrence.condition_occurrence_id'

        condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept.concept_id).first
        #1147127 = 'condition_occurrence.condition_occurrence_id'
        measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept_1.concept_id).first
        expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_1.measurement_time).to be_nil
        expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_1.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement_1.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement_1.value_source_value).to eq(@naaccr_item_value)

        measurement_3 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_discriminator_concept_1.concept_id).first
        expect(measurement_3.measurement_date).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_3.measurement_time).to be_nil
        expect(measurement_3.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_3.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_3.measurement_source_value).to eq(@naaccr_item_number_discriminator_1)
        expect(measurement_3.measurement_source_concept_id).to eq(@measurement_discriminator_source_concept_1.concept_id)
        expect(measurement_3.value_source_value).to eq(@naaccr_item_value_discriminator_1)

        condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept.concept_id).first
        measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept_2.concept_id).first
        expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_2.measurement_time).to be_nil
        expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_2.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement_2.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement_2.value_source_value).to eq(@naaccr_item_value)

        measurement_4 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1147127, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id,  measurement_concept_id: @measurement_discriminator_concept_2.concept_id).first
        expect(measurement_4.measurement_date).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_4.measurement_time).to be_nil
        expect(measurement_4.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_4.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_4.measurement_source_value).to eq(@naaccr_item_number_discriminator_2)
        expect(measurement_4.measurement_source_concept_id).to eq(@measurement_discriminator_source_concept_2.concept_id)
        expect(measurement_4.value_source_value).to eq(@naaccr_item_value_discriminator_2)
      end

      it 'pointing to EPISODE', focus: false do
        expect(ConditionOccurrence.count).to eq(2)
        expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(4) #1000000003 = ‘episode.episode_id’ concept

        condition_occurrence_1 = ConditionOccurrence.where(person_id: @person_1.person_id, condition_concept_id: @condition_concept.concept_id).first
        #1000000003 = ‘episode.episode_id’ concept
        measurement_1 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept_1.concept_id).first
        expect(measurement_1.measurement_date).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_1.measurement_time).to be_nil
        expect(measurement_1.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_1.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_1.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement_1.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement_1.value_source_value).to eq(@naaccr_item_value)

        measurement_3 = Measurement.where(person_id: @person_1.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_1.condition_occurrence_id,  measurement_concept_id: @measurement_discriminator_concept_1.concept_id).first
        expect(measurement_3.measurement_date).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_3.measurement_time).to be_nil
        expect(measurement_3.measurement_datetime).to eq(Date.parse(@diagnosis_date_1))
        expect(measurement_3.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_3.measurement_source_value).to eq(@naaccr_item_number_discriminator_1)
        expect(measurement_3.measurement_source_concept_id).to eq(@measurement_discriminator_source_concept_1.concept_id)
        expect(measurement_3.value_source_value).to eq(@naaccr_item_value_discriminator_1)

        condition_occurrence_2 = ConditionOccurrence.where(person_id: @person_2.person_id, condition_concept_id: @condition_concept.concept_id).first
        measurement_2 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id, measurement_concept_id: @measurement_concept.concept_id, value_as_concept_id: @measurement_value_as_concept_2.concept_id).first
        expect(measurement_2.measurement_date).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_2.measurement_time).to be_nil
        expect(measurement_2.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_2.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_2.measurement_source_value).to eq(@naaccr_item_number)
        expect(measurement_2.measurement_source_concept_id).to eq(@measurement_source_concept.concept_id)
        expect(measurement_2.value_source_value).to eq(@naaccr_item_value)

        measurement_4 = Measurement.where(person_id: @person_2.person_id, modifier_of_field_concept_id: 1000000003, modifier_of_event_id: condition_occurrence_2.condition_occurrence_id,  measurement_concept_id: @measurement_discriminator_concept_2.concept_id).first
        expect(measurement_4.measurement_date).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_4.measurement_time).to be_nil
        expect(measurement_4.measurement_datetime).to eq(Date.parse(@diagnosis_date_2))
        expect(measurement_4.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
        expect(measurement_4.measurement_source_value).to eq(@naaccr_item_number_discriminator_2)
        expect(measurement_4.measurement_source_concept_id).to eq(@measurement_discriminator_source_concept_2.concept_id)
        expect(measurement_4.value_source_value).to eq(@naaccr_item_value_discriminator_2)
      end
    end
  end

  describe "For 'Drug' treatments" do
    before(:each) do
      @naaccr_item_number_diagnosis_date = '390' #Date of Diagnosis
      @diagnosis_date = '19981022'
      @histology = '8140/3'
      @site = 'C61.9'
      @histology_site = "#{@histology}-#{@site}"

      @naaccr_item_number_chemo = '1390'           #RX Summ--Chemo
      @naaccr_item_value_chemo = '01'              #Chemotherapy, NOS.

      @naaccr_item_number_chemo_date = '1220'      #RX Summ--Chemo
      @naaccr_item_value_chemo_date = '20120701'

      @naaccr_item_number_hormone = '1400'         #RX Summ--Hormone
      @naaccr_item_value_hormone = '01'            #Hormone therapy administered as first course therapy.

      @naaccr_item_number_hormone_date = '1230'    #RX Date Hormone
      @naaccr_item_value_hormone_date = '20130701'

      @naaccr_item_number_brm = '1410'             #RX Summ--BRM
      @naaccr_item_value_brm = '01'                #Immunotherapy administered as first course therapy.

      @naaccr_item_number_brm_date = '1240'        #RX Date BRM
      @naaccr_item_value_brm_date = '20140701'

      #Person 1
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_diagnosis_date \
        , naaccr_item_value: @diagnosis_date \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_chemo \
        , naaccr_item_value: @naaccr_item_value_chemo  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_chemo_date \
        , naaccr_item_value: @naaccr_item_value_chemo_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_hormone \
        , naaccr_item_value: @naaccr_item_value_hormone  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_hormone_date \
        , naaccr_item_value: @naaccr_item_value_hormone_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_brm \
        , naaccr_item_value: @naaccr_item_value_brm  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_brm_date \
        , naaccr_item_value: @naaccr_item_value_brm_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @condition_concept = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      @episode_source_concept_chemo = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_chemo}@#{@naaccr_item_value_chemo}")
      @episode_source_concept_hormone = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_hormone}@#{@naaccr_item_value_hormone}")
      @episode_source_concept_brm = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_brm}@#{@naaccr_item_value_brm}")

      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it "creates entries in the EPISODE table", focus: false do
      #32531 = Treatment regimen
      expect(Episode.where(episode_concept_id: 32531).count).to eq(3)
      episode_chemo = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_chemo.concept_id).first
      expect(episode_chemo.person_id).to eq(@person_1.person_id)
      expect(episode_chemo.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_chemo.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_chemo_date))
      expect(episode_chemo.episode_end_datetime).to be_nil
      expect(episode_chemo.episode_object_concept_id).to eq(35803401) #35803401 = HemOnc Chemotherapy
      expect(episode_chemo.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_chemo.episode_source_value).to eq(@episode_source_concept_chemo.concept_code)
      expect(episode_chemo.episode_source_concept_id).to eq(@episode_source_concept_chemo.concept_id)

      episode_hormone = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_hormone.concept_id).first
      expect(episode_hormone.person_id).to eq(@person_1.person_id)
      expect(episode_hormone.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_hormone.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_hormone_date))
      expect(episode_hormone.episode_end_datetime).to be_nil
      expect(episode_hormone.episode_object_concept_id).to eq(35803407) #35803407 = HemOnc Hormonotherapy
      expect(episode_hormone.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_hormone.episode_source_value).to eq(@episode_source_concept_hormone.concept_code)
      expect(episode_hormone.episode_source_concept_id).to eq(@episode_source_concept_hormone.concept_id)

      episode_brm = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_brm.concept_id).first
      expect(episode_brm.person_id).to eq(@person_1.person_id)
      expect(episode_brm.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_brm.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_brm_date))
      expect(episode_brm.episode_end_datetime).to be_nil
      expect(episode_brm.episode_object_concept_id).to eq(35803410) #35803407 = HemOncImmunotherapy
      expect(episode_brm.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_brm.episode_source_value).to eq(@episode_source_concept_brm.concept_code)
      expect(episode_brm.episode_source_concept_id).to eq(@episode_source_concept_brm.concept_id)
    end

    it "creates entries in the DRUG_EXPOSURE table", focus: false do
      expect(DrugExposure.count).to eq(3)
      drug_exposure_chemo = DrugExposure.where(drug_source_concept_id: @episode_source_concept_chemo.concept_id).first
      expect(drug_exposure_chemo.drug_concept_id).to eq(0)
      expect(drug_exposure_chemo.person_id).to eq(@person_1.person_id)
      expect(drug_exposure_chemo.drug_exposure_start_date).to eq(Date.parse(@naaccr_item_value_chemo_date))
      expect(drug_exposure_chemo.drug_exposure_start_datetime).to eq(Date.parse(@naaccr_item_value_chemo_date))
      expect(drug_exposure_chemo.drug_exposure_end_date).to eq(Date.parse(@naaccr_item_value_chemo_date))
      expect(drug_exposure_chemo.drug_exposure_end_datetime).to eq(Date.parse(@naaccr_item_value_chemo_date))
      expect(drug_exposure_chemo.drug_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(drug_exposure_chemo.drug_source_value).to eq(@episode_source_concept_chemo.concept_code)
      expect(drug_exposure_chemo.drug_source_concept_id).to eq(@episode_source_concept_chemo.concept_id)

      drug_exposure_hormone = DrugExposure.where(drug_source_concept_id: @episode_source_concept_hormone.concept_id).first
      expect(drug_exposure_hormone.drug_concept_id).to eq(0)
      expect(drug_exposure_hormone.person_id).to eq(@person_1.person_id)
      expect(drug_exposure_hormone.drug_exposure_start_date).to eq(Date.parse(@naaccr_item_value_hormone_date))
      expect(drug_exposure_hormone.drug_exposure_start_datetime).to eq(Date.parse(@naaccr_item_value_hormone_date))
      expect(drug_exposure_hormone.drug_exposure_end_date).to eq(Date.parse(@naaccr_item_value_hormone_date))
      expect(drug_exposure_hormone.drug_exposure_end_datetime).to eq(Date.parse(@naaccr_item_value_hormone_date))
      expect(drug_exposure_hormone.drug_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(drug_exposure_hormone.drug_source_value).to eq(@episode_source_concept_hormone.concept_code)
      expect(drug_exposure_hormone.drug_source_concept_id).to eq(@episode_source_concept_hormone.concept_id)

      drug_exposure_brm = DrugExposure.where(drug_source_concept_id: @episode_source_concept_brm.concept_id).first
      expect(drug_exposure_brm.drug_concept_id).to eq(0)
      expect(drug_exposure_brm.person_id).to eq(@person_1.person_id)
      expect(drug_exposure_brm.drug_exposure_start_date).to eq(Date.parse(@naaccr_item_value_brm_date))
      expect(drug_exposure_brm.drug_exposure_start_datetime).to eq(Date.parse(@naaccr_item_value_brm_date))
      expect(drug_exposure_brm.drug_exposure_end_date).to eq(Date.parse(@naaccr_item_value_brm_date))
      expect(drug_exposure_brm.drug_exposure_end_datetime).to eq(Date.parse(@naaccr_item_value_brm_date))
      expect(drug_exposure_brm.drug_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(drug_exposure_brm.drug_source_value).to eq(@episode_source_concept_brm.concept_code)
      expect(drug_exposure_brm.drug_source_concept_id).to eq(@episode_source_concept_brm.concept_id)
    end

    it 'creates entries in EPISODE_EVENT pointing entries in DRUG_EXPOSURE to the corresponding entry in EPISODE', focus: false do
      episode_chemo = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_chemo.concept_id).first
      drug_exposure_chemo = DrugExposure.where(drug_source_concept_id: @episode_source_concept_chemo.concept_id).first
      #1147094 = drug_exposure.drug_exposure_id
      expect(EpisodeEvent.where(episode_id: episode_chemo.episode_id, event_id: drug_exposure_chemo.drug_exposure_id, episode_event_field_concept_id: 1147094).count).to eq(1)

      episode_hormone = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_hormone.concept_id).first
      drug_exposure_hormone = DrugExposure.where(drug_source_concept_id: @episode_source_concept_hormone.concept_id).first
      #1147094 = drug_exposure.drug_exposure_id
      expect(EpisodeEvent.where(episode_id: episode_hormone.episode_id, event_id: drug_exposure_hormone.drug_exposure_id, episode_event_field_concept_id: 1147094).count).to eq(1)

      episode_brm = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_brm.concept_id).first
      drug_exposure_brm = DrugExposure.where(drug_source_concept_id: @episode_source_concept_brm.concept_id).first
      #1147094 = drug_exposure.drug_exposure_id
      expect(EpisodeEvent.where(episode_id: episode_brm.episode_id, event_id: drug_exposure_brm.drug_exposure_id, episode_event_field_concept_id: 1147094).count).to eq(1)
    end

    it "links back to the corresponding 'Disease episode", focus: true do
      #32528='Disease First Occurrence'
      episode_disease = Episode.where(episode_concept_id: 32528, episode_object_concept_id: @condition_concept.concept_id).first

      episode_chemo = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_chemo.concept_id).first
      expect(episode_chemo.episode_parent_id).to eq(episode_disease.episode_id)

      episode_hormone = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_hormone.concept_id).first
      expect(episode_hormone.episode_parent_id).to eq(episode_disease.episode_id)

      episode_brm = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_source_concept_brm.concept_id).first
      expect(episode_brm.episode_parent_id).to eq(episode_disease.episode_id)
    end
  end

  describe "For 'Radiation' treatments" do
    before(:each) do
      @naaccr_item_number_diagnosis_date = '390' #Date of Diagnosis
      @diagnosis_date = '19981022'
      @histology = '8140/3'
      @site = 'C61.9'
      @histology_site = "#{@histology}-#{@site}"

      @naaccr_item_number_phase_1_radiation = '1506'      #Phase I Radiation Treatment Modality
      @naaccr_item_value_phase_1_radiation = '02'         #External beam, photons

      @naaccr_item_number_radiation_date = '1210'         #RX Date Radiation
      @naaccr_item_value_radiation_date = '20120701'

      @naaccr_item_number_radiation_end_date = '3220'     #RX Date Rad Ended
      @naaccr_item_value_radiation_end_date = '20120901'

      @naaccr_item_number_phase_2_radiation = '1516'      #Phase II Radiation Treatment Modality
      @naaccr_item_value_phase_2_radiation = '02'         #External beam, photons

      @naaccr_item_number_phase_3_radiation = '1526'      #Phase III Radiation Treatment Modality
      @naaccr_item_value_phase_3_radiation = '02'         #External beam, photons


      #Person 1
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_diagnosis_date \
        , naaccr_item_value: @diagnosis_date \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_1_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_1_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_radiation_date \
        , naaccr_item_value: @naaccr_item_value_radiation_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_radiation_end_date \
        , naaccr_item_value: @naaccr_item_value_radiation_end_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_2_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_2_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_3_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_3_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @condition_concept = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      @episode_object_concept_phase_1_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_1_radiation}@#{@naaccr_item_value_phase_1_radiation}")
      @episode_object_concept_phase_2_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_2_radiation}@#{@naaccr_item_value_phase_2_radiation}")
      @episode_object_concept_phase_3_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_3_radiation}@#{@naaccr_item_value_phase_3_radiation}")
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it "creates entries in the EPISODE table", focus: false do
      #32531 = Treatment regimen
      expect(Episode.where(episode_concept_id: 32531).count).to eq(3)
      episode_phase_1_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(episode_phase_1_radiation.person_id).to eq(@person_1.person_id)
      expect(episode_phase_1_radiation.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_phase_1_radiation.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(episode_phase_1_radiation.episode_end_datetime).to eq(Date.parse(@naaccr_item_value_radiation_end_date))
      expect(episode_phase_1_radiation.episode_object_concept_id).to eq(@episode_object_concept_phase_1_radiation.concept_id)
      expect(episode_phase_1_radiation.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_phase_1_radiation.episode_source_value).to eq(@episode_object_concept_phase_1_radiation.concept_code)
      expect(episode_phase_1_radiation.episode_source_concept_id).to eq(@episode_object_concept_phase_1_radiation.concept_id)

      episode_phase_2_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(episode_phase_2_radiation.person_id).to eq(@person_1.person_id)
      expect(episode_phase_2_radiation.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_phase_2_radiation.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(episode_phase_2_radiation.episode_end_datetime).to eq(Date.parse(@naaccr_item_value_radiation_end_date))
      expect(episode_phase_2_radiation.episode_object_concept_id).to eq(@episode_object_concept_phase_2_radiation.concept_id)
      expect(episode_phase_2_radiation.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_phase_2_radiation.episode_source_value).to eq(@episode_object_concept_phase_2_radiation.concept_code)
      expect(episode_phase_2_radiation.episode_source_concept_id).to eq(@episode_object_concept_phase_2_radiation.concept_id)

      episode_phase_3_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(episode_phase_3_radiation.person_id).to eq(@person_1.person_id)
      expect(episode_phase_3_radiation.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_phase_3_radiation.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(episode_phase_3_radiation.episode_end_datetime).to eq(Date.parse(@naaccr_item_value_radiation_end_date))
      expect(episode_phase_3_radiation.episode_object_concept_id).to eq(@episode_object_concept_phase_3_radiation.concept_id)
      expect(episode_phase_3_radiation.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_phase_3_radiation.episode_source_value).to eq(@episode_object_concept_phase_3_radiation.concept_code)
      expect(episode_phase_3_radiation.episode_source_concept_id).to eq(@episode_object_concept_phase_3_radiation.concept_id)
    end

    it "creates entries in the PROCEDURE_OCCURRENCE table", focus: false do
      expect(ProcedureOccurrence.count).to eq(3)
      procedure_occurrence_phase_1_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(procedure_occurrence_phase_1_radiation.person_id).to eq(@person_1.person_id)
      expect(procedure_occurrence_phase_1_radiation.procedure_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_1_radiation.procedure_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_1_radiation.procedure_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(procedure_occurrence_phase_1_radiation.quantity).to eq(1)
      expect(procedure_occurrence_phase_1_radiation.procedure_source_value).to eq(@episode_object_concept_phase_1_radiation.concept_code)
      expect(procedure_occurrence_phase_1_radiation.procedure_source_concept_id).to eq(@episode_object_concept_phase_1_radiation.concept_id)

      procedure_occurrence_phase_2_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(procedure_occurrence_phase_2_radiation.person_id).to eq(@person_1.person_id)
      expect(procedure_occurrence_phase_2_radiation.procedure_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_2_radiation.procedure_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_2_radiation.procedure_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(procedure_occurrence_phase_2_radiation.quantity).to eq(1)
      expect(procedure_occurrence_phase_2_radiation.procedure_source_value).to eq(@episode_object_concept_phase_2_radiation.concept_code)
      expect(procedure_occurrence_phase_2_radiation.procedure_source_concept_id).to eq(@episode_object_concept_phase_2_radiation.concept_id)

      procedure_occurrence_phase_3_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(procedure_occurrence_phase_3_radiation.person_id).to eq(@person_1.person_id)
      expect(procedure_occurrence_phase_3_radiation.procedure_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_3_radiation.procedure_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(procedure_occurrence_phase_3_radiation.procedure_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(procedure_occurrence_phase_3_radiation.quantity).to eq(1)
      expect(procedure_occurrence_phase_3_radiation.procedure_source_value).to eq(@episode_object_concept_phase_3_radiation.concept_code)
      expect(procedure_occurrence_phase_3_radiation.procedure_source_concept_id).to eq(@episode_object_concept_phase_3_radiation.concept_id)
    end

    it 'creates entries in EPISODE_EVENT pointing entries in PROCEDURE_OCCURRENCE to the corresponding entry in EPISODE', focus: false do
      episode_phase_1_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      procedure_occurrence_phase_1_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      #1147082 = procedure_occurrence.procedure_occurrence_id
      expect(EpisodeEvent.where(episode_id: episode_phase_1_radiation.episode_id, event_id: procedure_occurrence_phase_1_radiation.procedure_occurrence_id, episode_event_field_concept_id: 1147082).count).to eq(1)

      episode_phase_2_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      procedure_occurrence_phase_2_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      #1147082 = procedure_occurrence.procedure_occurrence_id
      expect(EpisodeEvent.where(episode_id: episode_phase_2_radiation.episode_id, event_id: procedure_occurrence_phase_2_radiation.procedure_occurrence_id, episode_event_field_concept_id: 1147082).count).to eq(1)

      episode_phase_3_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      procedure_occurrence_phase_3_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      #1147082 = procedure_occurrence.procedure_occurrence_id
      expect(EpisodeEvent.where(episode_id: episode_phase_3_radiation.episode_id, event_id: procedure_occurrence_phase_3_radiation.procedure_occurrence_id, episode_event_field_concept_id: 1147082).count).to eq(1)
    end

    it "links back to the corresponding 'Disease episode", focus: false do
      #32528='Disease First Occurrence'
      episode_disease = Episode.where(episode_concept_id: 32528, episode_object_concept_id: @condition_concept.concept_id).first

      episode_phase_1_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(episode_phase_1_radiation.episode_parent_id).to eq(episode_disease.episode_id)

      episode_phase_2_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(episode_phase_2_radiation.episode_parent_id).to eq(episode_disease.episode_id)

      episode_phase_3_radiation = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(episode_phase_2_radiation.episode_parent_id).to eq(episode_disease.episode_id)
    end
  end

  describe "For 'Surgery' treatments" do
    before(:each) do
      @naaccr_item_number_diagnosis_date = '390' #Date of Diagnosis
      @diagnosis_date_1 = '20051022'
      @histology_1 = '8140/3'
      @site_1 = 'C61.9'
      @histology_site_1 = "#{@histology_1}-#{@site_1}"

      @diagnosis_date_2 = '20100805'
      @histology_2 = '8825/3'
      @site_2 = 'C50.2'
      @histology_site_2 = "#{@histology_2}-#{@site_2}"

      @naaccr_item_number_surgery = '1290'                #RX Summ--Surg Prim Site
      @naaccr_item_value_surgery_1 = '50'                 #Prostate@Radical prostatectomy, NOS; total prostatectomy, NOS
      @naaccr_schema_concept_code_1 = 'Prostate'
      @naaccr_item_value_surgery_2 = '50'                 #Breast@Modified radical mastectomy
      @naaccr_schema_concept_code_2 = 'Breast'

      @naaccr_item_number_surgery_date = '1200'         #RX Date Surgery
      @naaccr_item_value_surgery_date_1 = '20120701'
      @naaccr_item_value_surgery_date_2 = '20120701'

      #Person 1
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_diagnosis_date \
        , naaccr_item_value: @diagnosis_date_1 \
        , histology: @histology_1 \
        , site: @site_1 \
        , histology_site: @histology_site_1 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_surgery \
        , naaccr_item_value: @naaccr_item_value_surgery_1  \
        , histology: @histology_1 \
        , site: @site_1 \
        , histology_site: @histology_site_1 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_surgery_date \
        , naaccr_item_value: @naaccr_item_value_surgery_date_1  \
        , histology: @histology_1 \
        , site: @site_1 \
        , histology_site: @histology_site_1 \
      )

      #Person 2
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: @naaccr_item_number_diagnosis_date \
        , naaccr_item_value: @diagnosis_date_1 \
        , histology: @histology_2 \
        , site: @site_2 \
        , histology_site: @histology_site_2 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: @naaccr_item_number_surgery \
        , naaccr_item_value: @naaccr_item_value_surgery_2  \
        , histology: @histology_2 \
        , site: @site_2 \
        , histology_site: @histology_site_2 \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_2.person_id \
        , record_id: '2' \
        , naaccr_item_number: @naaccr_item_number_surgery_date \
        , naaccr_item_value: @naaccr_item_value_surgery_date_2  \
        , histology: @histology_2 \
        , site: @site_2 \
        , histology_site: @histology_site_2 \
      )

      @condition_concept_1 = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site_1)
      @condition_concept_2 = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site_2)
      @episode_object_concept_surgery_1 = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_schema_concept_code_1}@#{@naaccr_item_number_surgery}@#{@naaccr_item_value_surgery_1}")
      @episode_object_concept_surgery_2 = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_schema_concept_code_2}@#{@naaccr_item_number_surgery}@#{@naaccr_item_value_surgery_2}")
      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it "creates entries in the EPISODE table", focus: false do
      #32531 = Treatment regimen
      expect(Episode.where(episode_concept_id: 32531).count).to eq(2)
      episode_surgery_1 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_1.concept_id).first
      expect(episode_surgery_1.person_id).to eq(@person_1.person_id)
      expect(episode_surgery_1.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_surgery_1.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date_1))
      expect(episode_surgery_1.episode_end_datetime).to be_nil
      expect(episode_surgery_1.episode_object_concept_id).to eq(@episode_object_concept_surgery_1.concept_id)
      expect(episode_surgery_1.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_surgery_1.episode_source_value).to eq(@episode_object_concept_surgery_1.concept_code)
      expect(episode_surgery_1.episode_source_concept_id).to eq(@episode_object_concept_surgery_1.concept_id)

      #32531 = Treatment regimen
      episode_surgery_2 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_2.concept_id).first
      expect(episode_surgery_2.person_id).to eq(@person_2.person_id)
      expect(episode_surgery_2.episode_concept_id).to eq(32531) #32531 = Treatment regimen
      expect(episode_surgery_2.episode_start_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date_2))
      expect(episode_surgery_2.episode_end_datetime).to be_nil
      expect(episode_surgery_2.episode_object_concept_id).to eq(@episode_object_concept_surgery_2.concept_id)
      expect(episode_surgery_2.episode_type_concept_id).to eq(32546) #32546 = Episode derived from registry
      expect(episode_surgery_2.episode_source_value).to eq(@episode_object_concept_surgery_2.concept_code)
      expect(episode_surgery_2.episode_source_concept_id).to eq(@episode_object_concept_surgery_2.concept_id)
    end

    it "creates entries in the PROCEDURE_OCCURRENCE table", focus: false do
      expect(ProcedureOccurrence.count).to eq(2)
      procedure_occurrence_surgery_1 = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery_1.concept_id).first
      expect(procedure_occurrence_surgery_1.person_id).to eq(@person_1.person_id)
      expect(procedure_occurrence_surgery_1.procedure_date).to eq(Date.parse(@naaccr_item_value_surgery_date_1))
      expect(procedure_occurrence_surgery_1.procedure_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date_1))
      expect(procedure_occurrence_surgery_1.procedure_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(procedure_occurrence_surgery_1.quantity).to eq(1)
      expect(procedure_occurrence_surgery_1.procedure_source_value).to eq(@episode_object_concept_surgery_1.concept_code)
      expect(procedure_occurrence_surgery_1.procedure_source_concept_id).to eq(@episode_object_concept_surgery_1.concept_id)

      procedure_occurrence_surgery_2 = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery_2.concept_id).first
      expect(procedure_occurrence_surgery_2.person_id).to eq(@person_2.person_id)
      expect(procedure_occurrence_surgery_2.procedure_date).to eq(Date.parse(@naaccr_item_value_surgery_date_2))
      expect(procedure_occurrence_surgery_2.procedure_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date_2))
      expect(procedure_occurrence_surgery_2.procedure_type_concept_id).to eq(32534) #32534=‘Tumor registry’ type concept
      expect(procedure_occurrence_surgery_2.quantity).to eq(1)
      expect(procedure_occurrence_surgery_2.procedure_source_value).to eq(@episode_object_concept_surgery_2.concept_code)
      expect(procedure_occurrence_surgery_2.procedure_source_concept_id).to eq(@episode_object_concept_surgery_2.concept_id)
    end

    it 'creates entries in EPISODE_EVENT pointing entries in PROCEDURE_OCCURRENCE to the corresponding entry in EPISODE', focus: false do
      episode_surgery_1 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_1.concept_id).first
      procedure_occurrence_surgery_1 = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery_1.concept_id).first
      #1147082 = procedure_occurrence.procedure_occurrence_id
      expect(EpisodeEvent.where(episode_id: episode_surgery_1.episode_id, event_id: procedure_occurrence_surgery_1.procedure_occurrence_id, episode_event_field_concept_id: 1147082).count).to eq(1)

      episode_surgery_2 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_2.concept_id).first
      procedure_occurrence_surgery_2 = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery_2.concept_id).first
      #1147082 = procedure_occurrence.procedure_occurrence_id
      expect(EpisodeEvent.where(episode_id: episode_surgery_2.episode_id, event_id: procedure_occurrence_surgery_2.procedure_occurrence_id, episode_event_field_concept_id: 1147082).count).to eq(1)
    end

    it "links back to the corresponding 'Disease episode", focus: false do
      #32528='Disease First Occurrence'
      episode_disease_1 = Episode.where(episode_concept_id: 32528, episode_object_concept_id: @condition_concept_1.concept_id).first
      episode_surgery_1 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_1.concept_id).first
      expect(episode_surgery_1.episode_parent_id).to eq(episode_disease_1.episode_id)
      episode_disease_2 = Episode.where(episode_concept_id: 32528, episode_object_concept_id: @condition_concept_2.concept_id).first
      episode_surgery_2 = Episode.where(episode_concept_id: 32531, episode_source_concept_id: @episode_object_concept_surgery_2.concept_id).first
      expect(episode_surgery_2.episode_parent_id).to eq(episode_disease_2.episode_id)
    end
  end

  describe 'Creating entries in MEASUREMENT table for a standard categorical schema-independent treatment modifier' do
    before(:each) do
      @naaccr_item_number_diagnosis_date = '390' #Date of Diagnosis
      @diagnosis_date = '20170630'
      @histology = '8140/3'
      @site = 'C61.9'
      @histology_site = "#{@histology}-#{@site}"

      @naaccr_item_number_surgery = '1290'                #RX Summ--Surg Prim Site
      @naaccr_item_value_surgery = '50'                 #Prostate@Radical prostatectomy, NOS; total prostatectomy, NOS
      @naaccr_schema_concept_code = 'Prostate'

      @naaccr_item_number_surgery_date = '1200'         #RX Date Surgery
      @naaccr_item_value_surgery_date = '20120701'

      @naaccr_item_number_surgical_margins = '1320'          #RX Summ--Surgical Margins
      @naaccr_item_value_surgical_margins  = '2'             #Microscopic residual tumor

      #Person 1
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_diagnosis_date \
        , naaccr_item_value: @diagnosis_date \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_surgery \
        , naaccr_item_value: @naaccr_item_value_surgery  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_surgery_date \
        , naaccr_item_value: @naaccr_item_value_surgery_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_surgical_margins \
        , naaccr_item_value: @naaccr_item_value_surgical_margins  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @naaccr_item_number_phase_1_radiation = '1506'      #Phase I Radiation Treatment Modality
      @naaccr_item_value_phase_1_radiation = '02'         #External beam, photons

      @naaccr_item_number_radiation_date = '1210'         #RX Date Radiation
      @naaccr_item_value_radiation_date = '20120701'

      @naaccr_item_number_radiation_end_date = '3220'     #RX Date Rad Ended
      @naaccr_item_value_radiation_end_date = '20120901'

      @naaccr_item_number_phase_2_radiation = '1516'      #Phase II Radiation Treatment Modality
      @naaccr_item_value_phase_2_radiation = '02'         #External beam, photons

      @naaccr_item_number_phase_3_radiation = '1526'      #Phase III Radiation Treatment Modality
      @naaccr_item_value_phase_3_radiation = '02'         #External beam, photons

      @naaccr_item_number_phase_1_radiation_external_beam_planning_tech = '1502'      #Phase I Radiation External Beam Planning Tech
      #MGURLEY 12/20/2019 This should be '05'.  The OMOP vocabulary needs to be fixed.
      @naaccr_item_value_phase_1_radiation_external_beam_planning_tech = '5'         #Intensity modulated therapy

      @naaccr_item_number_phase_2_radiation_external_beam_planning_tech = '1512'      #Phase II Radiation External Beam Planning Tech
      #MGURLEY 12/20/2019 This should be '05'.  The OMOP vocabulary needs to be fixed.
      @naaccr_item_value_phase_2_radiation_external_beam_planning_tech = '5'          #Intensity modulated therapy

      @naaccr_item_number_phase_3_radiation_external_beam_planning_tech = '1522'      #Phase III Radiation External Beam Planning Tech
      #MGURLEY 12/20/2019 This should be '05'.  The OMOP vocabulary needs to be fixed.
      @naaccr_item_value_phase_3_radiation_external_beam_planning_tech = '5'          #Intensity modulated therapy

      #Person 1
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_1_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_1_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_radiation_date \
        , naaccr_item_value: @naaccr_item_value_radiation_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_radiation_end_date \
        , naaccr_item_value: @naaccr_item_value_radiation_end_date  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_2_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_2_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_3_radiation \
        , naaccr_item_value: @naaccr_item_value_phase_3_radiation  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_1_radiation_external_beam_planning_tech \
        , naaccr_item_value: @naaccr_item_value_phase_1_radiation_external_beam_planning_tech  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_2_radiation_external_beam_planning_tech \
        , naaccr_item_value: @naaccr_item_value_phase_2_radiation_external_beam_planning_tech  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_3_radiation_external_beam_planning_tech \
        , naaccr_item_value: @naaccr_item_value_phase_3_radiation_external_beam_planning_tech  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @naaccr_item_number_phase_1_radiation_number_of_fractions = '1503'             #Phase I Number of Fractions
      @naaccr_item_value_phase_1_radiation_number_of_fractions = '010'

      @naaccr_item_number_phase_2_radiation_number_of_fractions = '1513'             #Phase II Number of Fractions
      @naaccr_item_value_phase_2_radiation_number_of_fractions = '0'                 #Radiation therapy was not administered to the patient.

      @naaccr_item_number_phase_3_radiation_number_of_fractions = '1523'             #Phase II Number of Fractions
      @naaccr_item_value_phase_3_radiation_number_of_fractions = '020'

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_1_radiation_number_of_fractions \
        , naaccr_item_value: @naaccr_item_value_phase_1_radiation_number_of_fractions  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_2_radiation_number_of_fractions \
        , naaccr_item_value: @naaccr_item_value_phase_2_radiation_number_of_fractions  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person_1.person_id \
        , record_id: '1' \
        , naaccr_item_number: @naaccr_item_number_phase_3_radiation_number_of_fractions \
        , naaccr_item_value: @naaccr_item_value_phase_3_radiation_number_of_fractions  \
        , histology: @histology \
        , site: @site \
        , histology_site: @histology_site \
      )

      @condition_concept = NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'ICDO3', concept_code: @histology_site)
      @episode_object_concept_surgery = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_schema_concept_code}@#{@naaccr_item_number_surgery}@#{@naaccr_item_value_surgery}")
      @measurement_surgical_margins_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_surgical_margins)
      @measurement_surgical_margins_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_surgical_margins)
      @measurement_surgical_margins_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_surgical_margins}@#{@naaccr_item_value_surgical_margins}")

      @episode_object_concept_phase_1_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_1_radiation}@#{@naaccr_item_value_phase_1_radiation}")
      @measurement_phase_1_radiation_external_beam_planning_tech_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_1_radiation_external_beam_planning_tech)
      @measurement_phase_1_radiation_external_beam_planning_tech_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_1_radiation_external_beam_planning_tech)
      @measurement_phase_1_radiation_external_beam_planning_tech_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_phase_1_radiation_external_beam_planning_tech}@#{@naaccr_item_value_phase_1_radiation_external_beam_planning_tech}")
      @measurement_phase_1_radiation_number_of_fractions_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_1_radiation_number_of_fractions)
      @measurement_phase_1_radiation_number_of_fraction_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_1_radiation_number_of_fractions)

      @episode_object_concept_phase_2_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_2_radiation}@#{@naaccr_item_value_phase_2_radiation}")
      @measurement_phase_2_radiation_external_beam_planning_tech_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_2_radiation_external_beam_planning_tech)
      @measurement_phase_2_radiation_external_beam_planning_tech_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_2_radiation_external_beam_planning_tech)
      @measurement_phase_2_radiation_external_beam_planning_tech_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_phase_2_radiation_external_beam_planning_tech}@#{@naaccr_item_value_phase_2_radiation_external_beam_planning_tech}")
      @measurement_phase_2_radiation_number_of_fractions_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_2_radiation_number_of_fractions)
      @measurement_phase_2_radiation_number_of_fractions_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_2_radiation_number_of_fractions)
      @measurement_phase_2_radiation_number_of_fractions_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_phase_2_radiation_number_of_fractions}@#{@naaccr_item_value_phase_2_radiation_number_of_fractions}")

      @episode_object_concept_phase_3_radiation = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: "#{@naaccr_item_number_phase_3_radiation}@#{@naaccr_item_value_phase_3_radiation}")
      @measurement_phase_3_radiation_external_beam_planning_tech_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_3_radiation_external_beam_planning_tech)
      @measurement_phase_3_radiation_external_beam_planning_tech_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_3_radiation_external_beam_planning_tech)
      @measurement_phase_3_radiation_external_beam_planning_tech_value_as_concept = NaaccrEtl::SpecSetup.naaccr_value_concept(concept_code: "#{@naaccr_item_number_phase_3_radiation_external_beam_planning_tech}@#{@naaccr_item_value_phase_3_radiation_external_beam_planning_tech}")
      @measurement_phase_3_radiation_number_of_fractions_concept =  NaaccrEtl::SpecSetup.standard_concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_3_radiation_number_of_fractions)
      @measurement_phase_3_radiation_number_of_fraction_source_concept = NaaccrEtl::SpecSetup.concept(vocabulary_id: 'NAACCR', concept_code: @naaccr_item_number_phase_3_radiation_number_of_fractions)

      NaaccrEtl::Setup.execute_naaccr_etl(@legacy)
    end

    it 'pointing to PROCEDURE_OCCURRENCE', focus: false do
      expect(Measurement.where(modifier_of_field_concept_id: 1147084).count).to eq(7)       #1147084 = ‘procedure_occurrence.procedure_concept_id’
      measurement_surgical_margins = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_surgical_margins_concept.concept_id).first
      expect(measurement_surgical_margins.person_id).to eq(@person_1.person_id)
      expect(measurement_surgical_margins.measurement_concept_id).to eq(@measurement_surgical_margins_concept.concept_id)
      expect(measurement_surgical_margins.measurement_date).to eq(Date.parse(@naaccr_item_value_surgery_date))
      expect(measurement_surgical_margins.measurement_time).to be_nil
      expect(measurement_surgical_margins.measurement_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date))
      expect(measurement_surgical_margins.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_surgical_margins.value_as_concept_id).to eq(@measurement_surgical_margins_value_as_concept.concept_id)
      expect(measurement_surgical_margins.measurement_source_value).to eq(@naaccr_item_number_surgical_margins)
      expect(measurement_surgical_margins.measurement_source_concept_id).to eq(@measurement_surgical_margins_source_concept.concept_id)
      expect(measurement_surgical_margins.value_source_value).to eq(@naaccr_item_value_surgical_margins)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery.concept_id).count).to eq(1)
      procedure_occurrence_surgery = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_surgery.concept_id).first
      expect(measurement_surgical_margins.modifier_of_event_id).to eq(procedure_occurrence_surgery.procedure_occurrence_id)
      expect(measurement_surgical_margins.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_1_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_1_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_1_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_1_radiation_external_beam_planning_tech)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_1_radiation_external_beam_planning_tech)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_1_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(measurement_phase_1_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(procedure_occurrence_phase_1_radiation.procedure_occurrence_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_2_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_2_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_2_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_2_radiation_external_beam_planning_tech)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_2_radiation_external_beam_planning_tech)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_2_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_2_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(measurement_phase_2_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(procedure_occurrence_phase_2_radiation.procedure_occurrence_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_3_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_3_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_3_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_3_radiation_external_beam_planning_tech)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_3_radiation_external_beam_planning_tech)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_3_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(measurement_phase_3_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(procedure_occurrence_phase_3_radiation.procedure_occurrence_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_1_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_1_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_1_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_1_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_1_radiation_number_of_fractions.value_as_concept_id).to be_nil
      expect(measurement_phase_1_radiation_number_of_fractions.value_as_number).to eq(@naaccr_item_value_phase_1_radiation_number_of_fractions.to_f)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_1_radiation_number_of_fractions)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_1_radiation_number_of_fraction_source_concept.concept_id)
      expect(measurement_phase_1_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_1_radiation_number_of_fractions)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_1_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(measurement_phase_1_radiation_number_of_fractions.modifier_of_event_id).to eq(procedure_occurrence_phase_1_radiation.procedure_occurrence_id)
      expect(measurement_phase_1_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_2_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_2_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_2_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_2_radiation_number_of_fractions.value_as_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_value_as_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.value_as_number).to be_nil
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_2_radiation_number_of_fractions)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_source_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_2_radiation_number_of_fractions)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_2_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(measurement_phase_2_radiation_number_of_fractions.modifier_of_event_id).to eq(procedure_occurrence_phase_2_radiation.procedure_occurrence_id)
      expect(measurement_phase_2_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_3_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1147084, measurement_concept_id: @measurement_phase_3_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_3_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_3_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_3_radiation_number_of_fractions.value_as_concept_id).to be_nil
      expect(measurement_phase_3_radiation_number_of_fractions.value_as_number).to eq(@naaccr_item_value_phase_3_radiation_number_of_fractions.to_f)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_3_radiation_number_of_fractions)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_3_radiation_number_of_fraction_source_concept.concept_id)
      expect(measurement_phase_3_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_3_radiation_number_of_fractions)
      expect(ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).count).to eq(1)
      procedure_occurrence_phase_3_radiation = ProcedureOccurrence.where(procedure_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(measurement_phase_3_radiation_number_of_fractions.modifier_of_event_id).to eq(procedure_occurrence_phase_3_radiation.procedure_occurrence_id)
      expect(measurement_phase_3_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1147084) #‘procedure_occurrence.procedure_concept_id’ concept
    end

    it 'pointing to EPISODE', focus: false do
      #1000000003 = ‘episode.episode_id’ concept
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(7)

      measurement_surgical_margins = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_surgical_margins_concept.concept_id).first
      expect(measurement_surgical_margins.person_id).to eq(@person_1.person_id)
      expect(measurement_surgical_margins.measurement_concept_id).to eq(@measurement_surgical_margins_concept.concept_id)
      expect(measurement_surgical_margins.measurement_date).to eq(Date.parse(@naaccr_item_value_surgery_date))
      expect(measurement_surgical_margins.measurement_time).to be_nil
      expect(measurement_surgical_margins.measurement_datetime).to eq(Date.parse(@naaccr_item_value_surgery_date))
      expect(measurement_surgical_margins.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_surgical_margins.value_as_concept_id).to eq(@measurement_surgical_margins_value_as_concept.concept_id)
      expect(measurement_surgical_margins.measurement_source_value).to eq(@naaccr_item_number_surgical_margins)
      expect(measurement_surgical_margins.measurement_source_concept_id).to eq(@measurement_surgical_margins_source_concept.concept_id)
      expect(measurement_surgical_margins.value_source_value).to eq(@naaccr_item_value_surgical_margins)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_surgery.concept_id).count).to eq(1)
      episode_surgery = Episode.where(episode_object_concept_id: @episode_object_concept_surgery.concept_id).first
      expect(measurement_surgical_margins.modifier_of_event_id).to eq(episode_surgery.episode_id)
      expect(measurement_surgical_margins.modifier_of_field_concept_id).to eq(1000000003) #1000000003=‘episode.episode_id’ concept

      measurement_phase_1_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_1_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_1_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_1_radiation_external_beam_planning_tech)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_1_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_1_radiation_external_beam_planning_tech)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      episode_phase_1_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(measurement_phase_1_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(episode_phase_1_radiation.episode_id)
      expect(measurement_phase_1_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1000000003) #1000000003=‘episode.episode_id’ concept

      measurement_phase_2_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_2_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_2_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_2_radiation_external_beam_planning_tech)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_2_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_2_radiation_external_beam_planning_tech)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_2_radiation.concept_id).count).to eq(1)
      episode_phase_2_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(measurement_phase_2_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(episode_phase_2_radiation.episode_id)
      expect(measurement_phase_2_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1000000003) #1000000003=‘episode.episode_id’ concept

      measurement_phase_3_radiation_external_beam_planning_tech = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id).first
      expect(measurement_phase_3_radiation_external_beam_planning_tech.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_time).to be_nil
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_3_radiation_external_beam_planning_tech.value_as_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_value_as_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_source_value).to eq(@naaccr_item_number_phase_3_radiation_external_beam_planning_tech)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.measurement_source_concept_id).to eq(@measurement_phase_3_radiation_external_beam_planning_tech_concept.concept_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.value_source_value).to eq(@naaccr_item_value_phase_3_radiation_external_beam_planning_tech)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_3_radiation.concept_id).count).to eq(1)
      episode_phase_3_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(measurement_phase_3_radiation_external_beam_planning_tech.modifier_of_event_id).to eq(episode_phase_3_radiation.episode_id)
      expect(measurement_phase_3_radiation_external_beam_planning_tech.modifier_of_field_concept_id).to eq(1000000003) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_1_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_1_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_1_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_1_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_1_radiation_number_of_fractions.value_as_concept_id).to be_nil
      expect(measurement_phase_1_radiation_number_of_fractions.value_as_number).to eq(@naaccr_item_value_phase_1_radiation_number_of_fractions.to_f)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_1_radiation_number_of_fractions)
      expect(measurement_phase_1_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_1_radiation_number_of_fraction_source_concept.concept_id)
      expect(measurement_phase_1_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_1_radiation_number_of_fractions)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      episode_phase_1_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_1_radiation.concept_id).first
      expect(measurement_phase_1_radiation_number_of_fractions.modifier_of_event_id).to eq(episode_phase_1_radiation.episode_id)
      expect(measurement_phase_1_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1000000003) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_2_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_2_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_2_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_2_radiation_number_of_fractions.value_as_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_value_as_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.value_as_number).to be_nil
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_2_radiation_number_of_fractions)
      expect(measurement_phase_2_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_2_radiation_number_of_fractions_source_concept.concept_id)
      expect(measurement_phase_2_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_2_radiation_number_of_fractions)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_1_radiation.concept_id).count).to eq(1)
      episode_phase_2_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_2_radiation.concept_id).first
      expect(measurement_phase_2_radiation_number_of_fractions.modifier_of_event_id).to eq(episode_phase_2_radiation.episode_id)
      expect(measurement_phase_2_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1000000003) #‘procedure_occurrence.procedure_concept_id’ concept

      measurement_phase_3_radiation_number_of_fractions = Measurement.where(modifier_of_field_concept_id: 1000000003, measurement_concept_id: @measurement_phase_3_radiation_number_of_fractions_concept.concept_id).first
      expect(measurement_phase_3_radiation_number_of_fractions.person_id).to eq(@person_1.person_id)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_concept_id).to eq(@measurement_phase_3_radiation_number_of_fractions_concept.concept_id)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_date).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_time).to be_nil
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_datetime).to eq(Date.parse(@naaccr_item_value_radiation_date))
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_type_concept_id).to eq(32534) # 32534 = ‘Tumor registry type concept
      expect(measurement_phase_3_radiation_number_of_fractions.value_as_concept_id).to be_nil
      expect(measurement_phase_3_radiation_number_of_fractions.value_as_number).to eq(@naaccr_item_value_phase_3_radiation_number_of_fractions.to_f)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_source_value).to eq(@naaccr_item_number_phase_3_radiation_number_of_fractions)
      expect(measurement_phase_3_radiation_number_of_fractions.measurement_source_concept_id).to eq(@measurement_phase_3_radiation_number_of_fraction_source_concept.concept_id)
      expect(measurement_phase_3_radiation_number_of_fractions.value_source_value).to eq(@naaccr_item_value_phase_3_radiation_number_of_fractions)
      expect(Episode.where(episode_object_concept_id: @episode_object_concept_phase_3_radiation.concept_id).count).to eq(1)
      episode_phase_3_radiation = Episode.where(episode_object_concept_id: @episode_object_concept_phase_3_radiation.concept_id).first
      expect(measurement_phase_3_radiation_number_of_fractions.modifier_of_event_id).to eq(episode_phase_3_radiation.episode_id)
      expect(measurement_phase_3_radiation_number_of_fractions.modifier_of_field_concept_id).to eq(1000000003) #‘procedure_occurrence.procedure_concept_id’ concept
    end
  end
end