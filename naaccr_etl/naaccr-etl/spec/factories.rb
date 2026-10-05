FactoryBot.define do
  factory :naaccr_data_point do
    person_id                   { nil }
    record_id                   { nil }
    naaccr_item_number          { nil }
    naaccr_item_value           { nil }
    histology                   { nil }
    site                        { nil }
    histology_site              { nil }
  end

  factory :person do
    sequence(:person_id)
    gender_concept_id                       { 0 }
    year_of_birth                           { 1971 }
    month_of_birth                          { 12 }
    day_of_birth                            { 10 }
    birth_datetime                          { Date.parse('1971-12-10') }
    race_concept_id                         { 0 }
    ethnicity_concept_id                    { 0 }
    location_id                             { nil }
    provider_id                             { nil }
    care_site_id                            { nil }
    person_source_value                     { nil }
    gender_source_value                     { nil }
    gender_source_concept_id                { 0 }
    race_source_value                       { nil }
    race_source_concept_id                  { 0 }
    ethnicity_source_value                  { nil }
    ethnicity_source_concept_id             { 0 }
  end

  factory :observation_period do
    sequence(:observation_period_id)
    person_id                              { nil }
    observation_period_start_date          { nil }
    observation_period_end_date            { nil }
    period_type_concept_id                 { 44814724 } #44814724-"Period covering healthcare encounters"
  end
end