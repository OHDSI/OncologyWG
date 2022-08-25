require 'csv'
namespace :vocabulary do
  desc "Prepare staging file"
  task(prepare_staging_file: :environment) do |t, args|
    mappings_from_file = CSV.new(File.open('lib/setup/data/naaccr_to_map_grading.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")      
    concept_relationship_stages = []
    mappings_from_file.each do |mapping_from_file|            
      if mapping_from_file['Maps To'] != '?'
        concept_relationship_stage = new_concept_relationship_stage
        concept_relationship_stage[:concept_code_1] = mapping_from_file['naaccr_value_code']
        concept_relationship_stage[:vocabulary_id_1] = 'NAACCR'        
        concept = Concept.where(concept_code: concept_relationship_stage[:concept_code_1], vocabulary_id: concept_relationship_stage[:vocabulary_id_1]).first
      
        puts concept_relationship_stage[:concept_code_1]
        puts concept_relationship_stage[:vocabulary_id_1]
        if concept
          puts 'we found the concept'
          puts concept_relationship_stage[:concept_code_1]
          concept_relationship_stage[:concept_name_1] = concept.concept_name
          concept_relationship_stage[:concept_class_id_1] = concept.concept_class_id
          concept_relationship_stage[:relationship_id] = 'maps to'        

          if mapping_from_file['Maps To'] == '0'
            concept = Concept.where(concept_id: mapping_from_file['Maps To']).first                                
          else
            concept = Concept.where(concept_id: mapping_from_file['Maps To'], standard_concept: 'S').first                    
          end
          if concept          
            puts 'we found the concept'
            puts mapping_from_file['Maps To']          
            concept_relationship_stage[:concept_code_2] = concept.concept_code
            concept_relationship_stage[:vocabulary_id_2] = 'Cancer Modifier'
            concept_relationship_stage[:concept_name_2] = concept.concept_name          
            concept_relationship_stage[:concept_class_id_2] = concept.concept_class_id                       
            concept_relationship_stage[:valid_start_date] = Date.today.to_s 
            concept_relationship_stage[:valid_end_date] = '2099-12-31' 
            concept_relationship_stage[:mapping_note] = mapping_from_file['mapping notes']
            concept_relationship_stages << concept_relationship_stage            
          else
            puts "we did not find the concept Cancer Modifier concept"
            puts mapping_from_file['Maps To']
          end        
        else
          puts "we did not find the concept NAACCR concept"
          puts concept_relationship_stage[:concept_code_1]
        end
      end
    end

    File.open 'lib/setup/data_out/sample_concept_relationship_stage.csv', 'w' do |f|
      f.print '"concept_code_1"'
      f.print ','
      f.print '"vocabulary_id_1"'      
      f.print ','      
      f.print '"concept_name_1"'            
      f.print ','      
      f.print '"concept_class_id_1"'            
      f.print ','      
      f.print '"relationship_id"'            
      f.print ','      
      f.print '"concept_code_2"'            
      f.print ','      
      f.print '"vocabulary_id_2"'            
      f.print ','      
      f.print '"concept_name_2"'            
      f.print ','      
      f.print '"concept_class_id_2"'            
      f.print ','      
      f.print '"valid_start_date"'            
      f.print ','      
      f.print '"valid_end_date"'            
      f.print ','      
      f.print '"mapping_note"'            
      f.puts ''
            
      concept_relationship_stages.each do |concept_relationship_stages|
        f.print "\"#{concept_relationship_stages[:concept_code_1]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:vocabulary_id_1]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:concept_name_1]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:concept_class_id_1]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:relationship_id]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:concept_code_2]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:vocabulary_id_2]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:concept_name_2]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:concept_class_id_2]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:valid_start_date]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:valid_end_date]}\""
        f.print ','              
        f.print "\"#{concept_relationship_stages[:mapping_note]}\""
        f.puts ''                      
      end
    end
  end
end

def new_concept_relationship_stage
  concept_relationship_stage = {}
  concept_relationship_stage[:concept_code_1]
  concept_relationship_stage[:vocabulary_id_1]
  concept_relationship_stage[:concept_name_1]
  concept_relationship_stage[:concept_class_id_1]
  concept_relationship_stage[:relationship_id]
  concept_relationship_stage[:concept_code_2]
  concept_relationship_stage[:vocabulary_id_2]
  concept_relationship_stage[:concept_name_2]
  concept_relationship_stage[:concept_class_id_2]  
  concept_relationship_stage[:valid_start_date]  
  concept_relationship_stage[:valid_end_date]  
  concept_relationship_stage[:mapping_note]    
  concept_relationship_stage  
end

# mapping notes
# item_number
# section
# naaccr_variable_code
# naaccr_variable_name
# Cancer Modifier Mapping
# Map Measurement? (assumes Value)
# Maps To
# Athena URL
# Already Done/
# naaccr_variable_domain
# concept_class_id
# naaccr_variable_standard_concept
# naaccr_item_start_date
# naaccr_item_end_date
# naaccr_item_400_parent
# naaccr_item_522_parent
# naaccr_variable_date
# naaccr_variable_parent
# naaccr_value_code
# naaccr_value_name
# naaccr_variable_domain-2
# concept_class_id-2
# naaccr_value_standard_concept

# concept_code_1
# vocabulary_id_1
# concept_name_1
# concept_class_id_1
# relationship_id
# concept_code_2
# vocabulary_id_2
# concept_name_2
# concept_class_id_2
# valid_start_date
# valid_end_date