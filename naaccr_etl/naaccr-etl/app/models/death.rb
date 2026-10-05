class Death < ApplicationRecord
  self.table_name = 'death'
  self.primary_key = 'person_id'
end
