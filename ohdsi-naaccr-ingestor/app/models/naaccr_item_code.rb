class NaaccrItemCode < ActiveRecord::Base
# class NaaccrItem < ApplicationRecord
  belongs_to :naaccr_item
  has_many :naaccr_schema_maps, as: :mappable
end