class NaaccrSchema < ActiveRecord::Base
# class NaaccrSchema < ApplicationRecord
  has_many :naaccr_schema_icdo_codes
  belongs_to :naaccr_staging_algorithm, optional: true
  SCHEMA_TYPE_SURGERY = 'Surgery'
  SCHEMA_TYPE_STAGING = 'Staging'
  SCHEMA_TYPES = [SCHEMA_TYPE_SURGERY, SCHEMA_TYPE_STAGING]
end