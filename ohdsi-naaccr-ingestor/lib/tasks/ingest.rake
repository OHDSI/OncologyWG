# bundle exec rake ingest:do
# bundle exec rake ingest:import_curated
# bundle exec rake ingest:export_uncurated
# bundle exec rake ingest:export_naaccr_schema_icdo_mappings

require 'csv'
require 'seer_api'
namespace :ingest do
  desc "Import curated"
  task(import_curated: :environment) do |t, args|
    naaccr_curated_items = CSV.new(File.open('lib/data/naaccr_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    naaccr_curated_items.each do |naaccr_curated_item|
      naaccr_item = NaaccrItem.where(item_omop_concept_code: naaccr_curated_item['item_omop_concept_code']).first
      if naaccr_item.present?
        naaccr_item.item_omop_domain_id = naaccr_curated_item['item_omop_domain_id']
        naaccr_item.item_curation_comments = naaccr_curated_item['item_curation_comments']
        naaccr_item.item_standard_concept = naaccr_curated_item['item_standard_concept']
        naaccr_item.treatment_type = naaccr_curated_item['treatment_type']
        naaccr_item.item_maps_to = naaccr_curated_item['item_maps_to']

        naaccr_item.save!

        naaccr_item_code = NaaccrItemCode.where(code_omop_concept_code: naaccr_curated_item['code_omop_concept_code']).first
        if naaccr_item_code
          naaccr_item_code.code_omop_domain_id = naaccr_curated_item['code_omop_domain_id']
          naaccr_item_code.code_curation_comments = naaccr_curated_item['code_curation_comments']
          naaccr_item_code.code_standard_concept = naaccr_curated_item['code_standard_concept']
          naaccr_item_code.code_maps_to = naaccr_curated_item['code_maps_to']
          naaccr_item_code.save!
        end
      end
    end
  end

  desc "Export uncurated"
  task(export_uncurated: :environment) do |t, args|
    headers = NaaccrItem.columns.map {|column| column.name }
    headers.concat(NaaccrItemCode.columns.map {|column| column.name })
    headers = headers - ['id', 'naaccr_item_id', 'created_at', 'updated_at']
    headers = headers + ['schema_name']
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    naaccr_items = NaaccrItem.where('note IS NULL OR note = ?', NaaccrItem::NOTE_NEW).order('item_number ASC, code ASC').joins("LEFT JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id LEFT JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode' LEFT JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id").select("naaccr_items.*, naaccr_item_codes.*, naaccr_schemas.schema_type || ':' || naaccr_schemas.title AS schema_name")

    CSV.open('lib/data_out/naaccr_uncurated.csv', "wb") do |csv|
      csv << row_header
      naaccr_items.each do |naaccr_item|
        row = row_template.dup
        row['item_number'] = naaccr_item.attributes['item_number']
        row['item_name'] = naaccr_item.attributes['item_name']
        row['section'] = naaccr_item.attributes['section']
        row['treatment_type'] = naaccr_item.attributes['treatment_type']
        row['item_maps_to'] = naaccr_item.attributes['item_maps_to']
        row['note'] = naaccr_item.attributes['note']
        row['item_omop_domain_id'] = naaccr_item.attributes['item_omop_domain_id']
        row['item_omop_concept_code'] = naaccr_item.attributes['item_omop_concept_code']
        row['item_curation_comments'] = naaccr_item.attributes['item_curation_comments']
        row['code'] = naaccr_item.attributes['code']
        row['code_description'] = naaccr_item.attributes['code_description']
        row['code_omop_domain_id'] = naaccr_item.attributes['code_omop_domain_id']
        row['code_omop_concept_code'] = naaccr_item.attributes['code_omop_concept_code']
        row['code_curation_comments'] = naaccr_item.attributes['code_curation_comments']
        row['code_maps_to'] = naaccr_item.attributes['code_maps_to']
        row['schema_name'] = naaccr_item.attributes['schema_name']
        csv << row
      end
    end
  end

  desc "Export schema ICDO mappings"
  task(export_naaccr_schema_icdo_mappings: :environment) do |t, args|
    headers = ['schema_name', 'icdo_code']
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    naaccr_schema_icdo_codes = NaaccrSchema.order("naaccr_schemas.schema_type || ':' || naaccr_schemas.title ASC, icdo_code ASC").joins("JOIN naaccr_schema_icdo_codes ON naaccr_schemas.id = naaccr_schema_icdo_codes.naaccr_schema_id").select("naaccr_schemas.schema_type || ':' || naaccr_schemas.title AS schema_name, naaccr_schema_icdo_codes.icdo_code")

    CSV.open('lib/data/naaccr_schema_icdo_mappings.csv', "wb") do |csv|
      csv << row_header
      naaccr_schema_icdo_codes.each do |naaccr_schema_icdo_code|
        row = row_template.dup
        row['schema_name'] = naaccr_schema_icdo_code.attributes['schema_name']
        row['icdo_code'] = naaccr_schema_icdo_code.attributes['icdo_code']
        csv << row
      end
    end
  end

  desc "Do"
  task(do: :environment) do |t, args|
    NaaccrSchema.delete_all
    NaaccrSchemaMap.delete_all
    NaaccrSchemaIcdoCode.delete_all
    NaaccrImport.delete_all
    NaaccrItem.delete_all
    NaaccrItemCode.delete_all

    naaccr_items = CSV.new(File.open('lib/data/NAACCR.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    previous_item_number = nil
    ni = nil
    naaccr_items.each do |naaccr_item|
      site_specific_status = 'Site-independent'
      item_number = naaccr_item['Item #']
      item_name = naaccr_item['Item Name']
      section = naaccr_item['Section']
      code = naaccr_item['Codes']
      if code == '43392'
        code = '10-19'
      end

      if item_number == '1290'
        site_specific_status = 'Site-specific Parent'
      end

      code_description = naaccr_item['Code Descriptions']
      note = naaccr_item['Note']
      NaaccrImport.create!(item_number: item_number, item_name: item_name, section: section, code: code, code_description: code_description, note: note)
      if item_number.present? && note != 'Retired'
        ni = NaaccrItem.create!(item_number: item_number, item_name: item_name, section: section, note: note, item_omop_concept_code: item_number, site_specific_status: site_specific_status)
        if code.present? && code != '..' && code != 'blank' && code != 'Blank'
          ni.naaccr_item_codes.build(code: code, code_description: code_description, code_omop_concept_code: "#{item_number}_#{code}")
          ni.save!
        end
      elsif code.present? && code != '..' && code != 'blank' && code != 'Blank'
        ni.naaccr_item_codes.build(code: code, code_description: code_description, code_omop_concept_code: "#{ni.item_number}_#{code}")
        ni.save!
      end
    end
    seer_api = SeerApi.initialize_seer_api
    surgery_titles = seer_api.surgery_titles
    surgery_titles[:response].each do |surgery_title|
      surgery_title_response = seer_api.surgery_title(ERB::Util.url_encode(surgery_title))
      naaccr_schema = NaaccrSchema.create!(title: surgery_title, schema_type: 'Surgery')
      naaccr_item_1290 = NaaccrItem.where(item_number: 1290).first
      @level_0 = nil
      @level_1 = nil
      @level_2 = nil
      @previous_level = nil
      code_omop_concept_codes = []
      surgery_title_response[:response]['row'].each do |code|
        if code['code'].present?
          # naaccr_item.naaccr_item_codes.build(code: code['code'], code_description: code['description'], code_omop_concept_code: "#{naaccr_item_1290.item_number}_#{surgery_title}_#{code['code']}")
          code_description = determine_code_description(code['description'], code['level'], surgery_title)
          code_omop_concept_code = "#{naaccr_item_1290.item_number}_#{surgery_title}_#{code['code']}"
          code_omop_concept_codes << code_omop_concept_code
          naaccr_item_1290.naaccr_item_codes.build(code: code['code'], code_description: code_description, code_omop_concept_code: code_omop_concept_code)
          @previous_level = code['level']
        end
      end
      naaccr_item_1290.save!
      NaaccrItemCode.where(code_omop_concept_code: code_omop_concept_codes).all.each do |naaccr_item_code|
        NaaccrSchemaMap.create!(naaccr_schema: naaccr_schema, mappable: naaccr_item_code)
      end

      site_inclusions = surgery_title_response[:response]['site_inclusions']
      site_inclusions.split(',').each do |site_inclusion|
        if site_inclusion.include?('-')
          begin_site, end_site = site_inclusion.split('-')
          begin_site_number = begin_site.match(/\d+$/).to_s.to_i
          end_site_number = end_site.match(/\d+$/).to_s.to_i

          while begin_site_number <= end_site_number
            icdo_code = "C#{begin_site_number.to_s.rjust(3, '0').insert(2,'.')}"
            concept = Concept.where(concept_class_id: 'ICDO Topography', concept_code: icdo_code).first
            if concept.present?
              naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code)
            end

            begin_site_number+=1
          end

        else
          naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: site_inclusion.to_s.rjust(3, '0').insert(3,'.'))
        end
        naaccr_schema.save!
      end
    end
  end
end

def determine_code_description(description, level, surgery_title)
  # puts 'love the booch'
  # puts description
  # puts level
  code_description = nil
  case level
  when 0
    code_description = "#{surgery_title} #{description}"
    @level_0 = description.gsub(', NOS', '')
  when 1
    code_description = "#{surgery_title} #{@level_0} #{description}"
    @level_1 = description.gsub(', NOS', '')
  when 2
    code_description = "#{surgery_title} #{@level_0} #{@level_1} #{description}"
    @level_2 = description.gsub(', NOS', '')
  when 3
    code_description = "#{surgery_title} #{@level_0} #{@level_1} #{@level_2} #{description}"
    @level_3 = description.gsub(', NOS', '')
  end
  code_description
end