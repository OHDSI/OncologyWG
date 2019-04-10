class NaaccrSchemaIcdoCode < ActiveRecord::Base
# class NaaccrSchemaIcdoCode < ApplicationRecord
  belongs_to :naaccr_schema
  ICDO_TYPE_TOPOGRAPHY = 'ICDO Topography'
  ICDO_TYPE_MORPHOLOGY = 'ICDO Morphology'
  ICDO_TYPE_TOPOGRAPHY_MORPHOLOGY = 'ICDO Topography Morphology'
  ICDO_TYPES = [ICDO_TYPE_TOPOGRAPHY, ICDO_TYPE_MORPHOLOGY, ICDO_TYPE_TOPOGRAPHY_MORPHOLOGY]
end