class NaaccrSchemaMap < ActiveRecord::Base
  belongs_to :naaccr_schema
  belongs_to :mappable, polymorphic: true
end