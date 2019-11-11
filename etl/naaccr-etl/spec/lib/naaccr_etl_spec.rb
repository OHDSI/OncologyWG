require 'rails_helper'
describe NaaccrEtl do
  before(:each) do
    @person = FactoryBot.create(:person)
  end

  after(:each) do
    NaaccrEtl::SpecSetup.teardown
  end

  it 'creates an entry in the CONDITION_OCCURRENCE table', focus: false do
    FactoryBot.create(:naaccr_data_point \
      , person_id: @person.person_id \
      , record_id: '1' \
      , naaccr_item_number: '390' \
      , naaccr_item_value: '20170630' \
      , histology: '8140/3' \
      , site: 'C61.9' \
      , histology_site: '8140/3-C61.9' \
    )
    NaaccrEtl::Setup.execute_naaccr_etl
    expect(ConditionOccurrence.count).to eq(1)
  end

  describe 'Creating entries in MEASUREMENT table for a diagnosis modifier standard categorical' do
    before(:each) do
      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: '390' \
        , naaccr_item_value: '20170630' \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: '8140/3-C61.9' \
      )

      FactoryBot.create(:naaccr_data_point \
        , person_id: @person.person_id \
        , record_id: '1' \
        , naaccr_item_number: '1182' \
        , naaccr_item_value: '1' \
        , histology: '8140/3' \
        , site: 'C61.9' \
        , histology_site: '8140/3-C61.9' \
      )
      NaaccrEtl::Setup.execute_naaccr_etl
    end

    it 'pointing to CONDITION_OCCURRENCE' do
      expect(ConditionOccurrence.count).to eq(1)
      #1147127 = 'condition_occurrence.condition_occurrence_id'
      expect(Measurement.where(modifier_of_field_concept_id: 1147127).count).to eq(1)
    end

    it 'pointin to EPISODE' do
      expect(Episode.count).to eq(1)
      #1000000003 = 'episode.episode_id'
      expect(Measurement.where(modifier_of_field_concept_id: 1000000003).count).to eq(1)
    end
  end
end