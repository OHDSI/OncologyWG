# bundle exec rake ingest:do
# bundle exec rake ingest:import_curated
# bundle exec rake ingest:do_expansion
# bundle exec rake ingest:schemas

# bundle exec rake ingest:export_uncurated
# bundle exec rake ingest:export_naaccr_schema_icdo_mappings

require 'csv'
require 'seer_api'
namespace :ingest do
  desc "Schemas"
  task(schemas: :environment) do |t, args|
    seer_api = SeerApi.initialize_seer_api
    naaccr_version = NaaccrVersion.where(version: '18').first

    # NaaccrSchema.where(schema_type: NaaccrSchema::SCHEMA_TYPE_STAGING).each do |naaccr_schema|
    #   naaccr_schema.naaccr_schema_icdo_codes.each do |naaccr_schema_icdo_code|
    #     naaccr_schema_icdo_code.destroy!
    #   end
    # end

    # seer_id: ['prostate']
    NaaccrSchema.where(schema_type: NaaccrSchema::SCHEMA_TYPE_STAGING, icdo_processed: false).all.each do |naaccr_schema|
      schema = seer_api.schema(naaccr_schema.naaccr_staging_algorithm.algorithm, naaccr_schema.seer_id)
      naaccr_schema.schema_selection_table = schema[:response]['schema_selection_table']
      naaccr_schema.save!
      #come back to associate ICDO codes with schemas later

      table = seer_api.table(naaccr_schema.naaccr_staging_algorithm.algorithm, schema[:response]['schema_selection_table'])
      puts table[:response]['rows'].first.first

      site_inclusions = table[:response]['rows'].first.first
      site_inclusions.split(',').each do |site_inclusion|
        if site_inclusion.include?('-')
          begin_site, end_site = site_inclusion.split('-')
          begin_site_number = begin_site.match(/\d+$/).to_s.to_i
          end_site_number = end_site.match(/\d+$/).to_s.to_i

          while begin_site_number <= end_site_number
            icdo_code = "C#{begin_site_number.to_s.rjust(3, '0').insert(2,'.')}"
            concept = Concept.where(concept_class_id: 'ICDO Topography', concept_code: icdo_code).first
            if concept.present?
              naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code, icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY)
            end

            begin_site_number+=1
          end

        else
          naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: site_inclusion.to_s.rjust(3, '0').insert(3,'.'), icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY)
        end
        naaccr_schema.save!
      end

      histology_inclusions = table[:response]['rows'].first[1]
      histology_inclusions.split(',').each do |histology_inclusion|
        if histology_inclusion.include?('-')
          histology_inclusion.strip!
          begin_histology, end_histology = histology_inclusion.split('-')
          # begin_histology_number = begin_histology[0..2].to_i
          # end_histology_number = end_histology[0..2].to_i
          begin_histology_number = begin_histology.to_i
          end_histology_number = end_histology.to_i

          puts 'schema'
          puts naaccr_schema.naaccr_staging_algorithm.name
          puts naaccr_schema.title
          puts naaccr_schema.seer_id
          puts naaccr_schema.schema_selection_table
          puts 'begin_histology_number'
          puts begin_histology
          puts begin_histology_number
          puts 'end_histology_number'
          puts end_histology
          puts end_histology_number
          while begin_histology_number <= end_histology_number
            ['0','1','2','3','6'].each do |grade|
              puts begin_histology_number
              puts grade
              icdo_code = "#{begin_histology_number.to_s.insert(4,'/')}#{grade}"
              puts icdo_code
              concept = Concept.where(concept_class_id: 'ICDO Histology', concept_code: icdo_code).first
              if concept.present?
                naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code, icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_MORPHOLOGY)
              end
            end

            begin_histology_number+=1
          end

        else
          puts 'single lady'
          ['0','1','2','3','6'].each do |grade|
            puts 'begin_histology_number'
            puts begin_histology_number
            if begin_histology_number.present?
              icdo_code = "#{begin_histology_number.to_s.insert(4,'/')}#{grade}"
              concept = Concept.where(concept_class_id: 'ICDO Histology', concept_code: icdo_code).first
              if concept.present?
                naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code, icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_MORPHOLOGY)
              end
            end
          end
        end
        naaccr_schema.icdo_processed = true
        naaccr_schema.save!
      end
    end

    NaaccrSchema.where(schema_type: NaaccrSchema::SCHEMA_TYPE_STAGING).all.each do |naaccr_schema|
      puts naaccr_schema.title
      naaccr_schema_icdo_code_morphologies = naaccr_schema.naaccr_schema_icdo_codes.where(icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_MORPHOLOGY)
      naaccr_schema.naaccr_schema_icdo_codes.where(icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY).each do |naaccr_schema_icdo_code_topography|
        naaccr_schema_icdo_code_morphologies.each do |naaccr_schema_icdo_code_morphology|
          icdo_code = "#{naaccr_schema_icdo_code_morphology.icdo_code}-#{naaccr_schema_icdo_code_topography.icdo_code}"
          concept = Concept.where(concept_class_id: 'ICDO Condition', concept_code: icdo_code).first
          if concept.present?
            naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code, icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY_MORPHOLOGY)
          end
        end
      end
      naaccr_schema.save!
    end
  end

  desc "Import curated"
  task(import_curated: :environment) do |t, args|
    naaccr_version = NaaccrVersion.where(version: '18').first
    naaccr_curated_items = CSV.new(File.open('lib/data/naaccr_curated.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    naaccr_curated_items.each do |naaccr_curated_item|
      puts naaccr_curated_item['item_omop_concept_code']
      naaccr_item = NaaccrItem.where(naaccr_version_id: naaccr_version.id, item_omop_concept_code: naaccr_curated_item['item_omop_concept_code']).first
      if naaccr_item.present?
        naaccr_item.item_omop_domain_id = naaccr_curated_item['item_omop_domain_id']
        naaccr_item.item_curation_comments = naaccr_curated_item['item_curation_comments']
        naaccr_item.item_standard_concept = naaccr_curated_item['item_standard_concept']
        naaccr_item.treatment_type = naaccr_curated_item['treatment_type']
        naaccr_item.item_maps_to = naaccr_curated_item['item_maps_to']
        naaccr_item.etl_instructions = naaccr_curated_item['etl_instructions']

        naaccr_item.save!

        naaccr_item_code = naaccr_item.naaccr_item_codes.where(code_omop_concept_code: naaccr_curated_item['code_omop_concept_code']).first
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
    naaccr_version = NaaccrVersion.where(version: '18').first
    headers = NaaccrItem.columns.map {|column| column.name }
    headers.concat(NaaccrItemCode.columns.map {|column| column.name })
    headers = headers - ['naaccr_version_id', 'id', 'naaccr_item_id', 'created_at', 'updated_at', 'site_specific_status', 'year_implemented', 'version_implemented', 'year_retired', 'version_retired', 'provenance']

    headers = headers + ['version','schema_name']
    row_header = CSV::Row.new(headers, headers, true)
    row_template = CSV::Row.new(headers, [], false)
    naaccr_items = NaaccrItem.joins(:naaccr_version).where('naaccr_version_id = ? AND note IS NULL OR note = ?', naaccr_version.id, NaaccrItem::NOTE_NEW).order('item_number::int ASC, code ASC').joins("LEFT JOIN naaccr_item_codes ON naaccr_items.id = naaccr_item_codes.naaccr_item_id LEFT JOIN naaccr_schema_maps ON naaccr_item_codes.id = naaccr_schema_maps.mappable_id AND naaccr_schema_maps.mappable_type = 'NaaccrItemCode' LEFT JOIN naaccr_schemas ON naaccr_schema_maps.naaccr_schema_id = naaccr_schemas.id").select("naaccr_versions.version, naaccr_items.*, naaccr_item_codes.*, naaccr_schemas.schema_type || ':' || naaccr_schemas.title AS schema_name")

    CSV.open('lib/data_out/naaccr_uncurated.csv', "wb") do |csv|
      csv << row_header
      naaccr_items.each do |naaccr_item|
        row = row_template.dup
        row['version'] = naaccr_item.attributes['version']
        row['item_number'] = naaccr_item.attributes['item_number']
        row['item_name'] = naaccr_item.attributes['item_name']
        row['section'] = naaccr_item.attributes['section']
        row['treatment_type'] = naaccr_item.attributes['treatment_type']
        row['item_maps_to'] = naaccr_item.attributes['item_maps_to']
        row['note'] = naaccr_item.attributes['note']
        row['item_omop_domain_id'] = naaccr_item.attributes['item_omop_domain_id']
        row['item_omop_concept_code'] = naaccr_item.attributes['item_omop_concept_code']
        row['item_curation_comments'] = naaccr_item.attributes['item_curation_comments']
        row['etl_instructions'] = naaccr_item.attributes['etl_instructions']
        row['code'] = naaccr_item.attributes['code']

        if naaccr_item.attributes['code_description'].present?
          row['code_description'] = naaccr_item.attributes['code_description'].encode!('ASCII', invalid: :replace, undef: :replace).gsub("\n", '')
        else
          row['code_description'] = naaccr_item.attributes['code_description']
        end
        row['code_omop_domain_id'] = naaccr_item.attributes['code_omop_domain_id']
        row['code_omop_concept_code'] = naaccr_item.attributes['code_omop_concept_code']
        row['code_curation_comments'] = naaccr_item.attributes['code_curation_comments']
        row['code_standard_concept'] = naaccr_item.attributes['code_standard_concept']
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
    NaaccrVersion.delete_all
    NaaccrSchema.delete_all
    NaaccrSchemaMap.delete_all
    NaaccrSchemaIcdoCode.delete_all
    NaaccrImport.delete_all
    NaaccrItem.delete_all
    NaaccrItemCode.delete_all
    NaaccrStagingAlgorithm.delete_all

    seer_api = SeerApi.initialize_seer_api
    naaccr_versions = seer_api.naaccr_versions
    naaccr_versions[:response].each do |naaccr_version|
      if naaccr_version['version'].to_i >= 16
        naaccr_version = NaaccrVersion.create!(version: naaccr_version['version'])
        naaccr_items = seer_api.naaccr_items(naaccr_version['version'])
        naaccr_items[:response].each do |naaccr_item|
          site_specific_status = NaaccrItem::SITE_SPECIFIC_STATUS_SITE_INDEPENDENT
          naaccr_item_detail = seer_api.naaccr_item(naaccr_version['version'], naaccr_item['item'])
          naaccr_item_detail = naaccr_item_detail[:response]
          puts 'moomin'
          puts naaccr_item_detail
          puts naaccr_version['version']
          puts naaccr_item['item']

          documentation = Nokogiri::HTML.parse(naaccr_item_detail['documentation'])

          puts 'hello booch'
          puts documentation.css('table.naaccr-summary-table tr')[0]
          puts documentation.css('table.naaccr-summary-table tr')[1]
          case naaccr_version['version'].to_i
          when 16
            year_implemented = documentation.css('table.naaccr-summary-table tr')[1].css('td')[4].try(:text)
            version_implemented = documentation.css('table.naaccr-summary-table tr')[1].css('td')[5].try(:text)
            year_retired = documentation.css('table.naaccr-summary-table tr')[1].css('td')[6].try(:text)
            version_retired = documentation.css('table.naaccr-summary-table tr')[1].css('td')[7].try(:text)
          when 18
            year_implemented = documentation.css('table.naaccr-summary-table tr')[1].css('td')[3].try(:text)
            version_implemented = documentation.css('table.naaccr-summary-table tr')[1].css('td')[4].try(:text)
            year_retired = documentation.css('table.naaccr-summary-table tr')[1].css('td')[5].try(:text)
            version_retired = documentation.css('table.naaccr-summary-table tr')[1].css('td')[6].try(:text)
          end

          if naaccr_item['item'].to_s == '1290'
            site_specific_status = NaaccrItem::SITE_SPECIFIC_STATUS_SITE_SPECIFIC
          end

          naaccr_item_saved = NaaccrItem.create!(naaccr_version_id: naaccr_version.id, item_number: naaccr_item['item'], item_name: naaccr_item['name'], section: naaccr_item_detail['section'], item_omop_concept_code: naaccr_item['item'], site_specific_status: site_specific_status, year_implemented: year_implemented, version_implemented: version_implemented, year_retired: year_retired, version_retired: version_retired, item_omop_domain_id: nil)
          documentation.css('tr.code-row').each do |row|
            code = row.css('td.code-nbr').text.strip
            code_description = row.css('td.code-desc').text.strip
            unless ['(Fill spaces)', '..', '...'].include?(code) || code_description.blank?
              naaccr_item_saved.naaccr_item_codes.build(code: code, code_description: code_description, code_omop_concept_code: "#{naaccr_item['item']}_#{code}", provenance: NaaccrItemCode::PROVENANCE_BASE_NAACCR_DATA_DICTIONARY, code_omop_domain_id: nil)
              naaccr_item_saved.save!
            end
          end
        end
      end
      if naaccr_version['version'].to_i == 18
        naaccr_version = NaaccrVersion.where(version: naaccr_version['version']).first
        seer_api = SeerApi.initialize_seer_api
        surgery_titles = seer_api.surgery_titles
        surgery_titles[:response].each do |surgery_title|
          surgery_title_response = seer_api.surgery_title(ERB::Util.url_encode(surgery_title))
          naaccr_schema = NaaccrSchema.create!(title: surgery_title, schema_type: NaaccrSchema::SCHEMA_TYPE_SURGERY)
          naaccr_item_1290 = NaaccrItem.where(naaccr_version_id: naaccr_version.id, item_number: '1290').first
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
              naaccr_item_1290.naaccr_item_codes.build(code: code['code'], code_description: code_description, code_omop_concept_code: code_omop_concept_code, provenance: NaaccrItemCode::PROVENANCE_SEER_API, code_omop_domain_id: NaaccrItemCode::CODE_OMOP_DOMAIN_ID_TREATMENT)
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
                  naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: icdo_code, icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY)
                end

                begin_site_number+=1
              end

            else
              naaccr_schema.naaccr_schema_icdo_codes.build(icdo_code: site_inclusion.to_s.rjust(3, '0').insert(3,'.'), icdo_type: NaaccrSchemaIcdoCode::ICDO_TYPE_TOPOGRAPHY)
            end
            naaccr_schema.save!
          end
        end
      end

      naaccr_items = CSV.new(File.open('lib/data/NAACCR.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      naaccr_items.each do |naaccr_item|
        if naaccr_item['Item #'].present?
          puts naaccr_item['Item #']
          NaaccrItem.where(item_number: naaccr_item['Item #'].to_s).each do |ni|
            puts 'hello'
            puts naaccr_item['Section']
            if !NaaccrItem::RELEVANT_SECTIONS.include?(naaccr_item['Section'])
              item_omop_domain_id = NaaccrItem::ITEM_OMOP_DOMAIN_ID_NONE
              code_omop_domain_id = NaaccrItemCode::CODE_OMOP_DOMAIN_ID_NONE
            else
              item_omop_domain_id = nil
              code_omop_domain_id = nil
            end

            ni.section = naaccr_item['Section']
            ni.item_omop_domain_id = item_omop_domain_id
            ni.naaccr_item_codes.each do |naaccr_item_code|
              naaccr_item_code.code_omop_domain_id = code_omop_domain_id
            end
            ni.save!
          end
        end
      end
    end
  end

  desc "Do expansion"
  task(do_expansion: :environment) do |t, args|
    seer_api = SeerApi.initialize_seer_api
    naaccr_version = NaaccrVersion.where(version: '18').first

    staging_algorithims = seer_api.staging_algorithims
    staging_algorithims[:response].each do |staging_algorithim|
      NaaccrStagingAlgorithm.where(name: staging_algorithim['name'], algorithm: staging_algorithim['algorithm']).first_or_create
    end

    NaaccrStagingAlgorithm.all.each do |naaccr_staging_algorithm|
      schemas = seer_api.schemas(naaccr_staging_algorithm.algorithm)
      schemas[:response].each do |schema|
        naaccr_schema = NaaccrSchema.where(title: schema['name'], seer_id: schema['id'], schema_type: NaaccrSchema::SCHEMA_TYPE_STAGING, naaccr_staging_algorithm_id: naaccr_staging_algorithm.id).first_or_create
      end
    end

    # require 'seer_api'
    # seer_api = SeerApi.initialize_seer_api
    # seer_id: ['prostate']
    NaaccrSchema.where(schema_type: NaaccrSchema::SCHEMA_TYPE_STAGING, processed: false).all.each do |naaccr_schema|
      schema = seer_api.schema(naaccr_schema.naaccr_staging_algorithm.algorithm, naaccr_schema.seer_id)
      puts 'this is the schema!'
      puts naaccr_schema.title
      puts schema
      schema[:response]['inputs'].each do |input|
        naaccr_item = NaaccrItem.where(naaccr_version_id: naaccr_version.id, item_number: input['naaccr_item']).first
        puts 'We are looking at NAACCR item:'
        puts naaccr_item.item_name
        puts 'Begin item API keys'
        puts input.keys
        puts 'End item API keys'
        if naaccr_item.item_omop_domain_id.blank?
          puts 'blank NAACCR item'
        elsif naaccr_item.item_omop_domain_id == 'None'
          puts "NAACCR item we decided to skip because 'None'"
        elsif naaccr_item.item_omop_domain_id == 'Date'
          puts "NAACCR item we decided to skip because 'Date'"
        elsif naaccr_item.item_omop_domain_id == 'Measurement Number'
          puts "NAACCR item we decided to skip because 'Measurement Number'"
        else
          puts 'NAACCR item we decided to keep'
          puts input['naaccr_item']

          schema_specific_naaccr_item_codes = false
          if naaccr_item.item_name.match('CS Site-Specific Factor').present?
            puts 'We have a C variable!'
            puts 'Base Name'
            puts naaccr_item.item_name
            puts 'API Name'
            puts input['name']
            naaccr_item_site_specific = NaaccrItem.where(naaccr_version_id: naaccr_version.id, item_number: naaccr_item.item_number, item_name: "#{naaccr_schema.naaccr_staging_algorithm.algorithm}-#{naaccr_schema.seer_id}-#{naaccr_item.item_name}-#{input['name']}", section: naaccr_item.section, item_omop_concept_code: "#{naaccr_schema.naaccr_staging_algorithm.algorithm}-#{naaccr_schema.seer_id}-#{naaccr_item.item_number}", site_specific_status: NaaccrItem::SITE_SPECIFIC_STATUS_SITE_SPECIFIC, year_implemented: naaccr_item.year_implemented, version_implemented: naaccr_item.version_implemented, year_retired: naaccr_item.year_retired, version_retired: naaccr_item.version_retired, item_omop_domain_id: NaaccrItem::ITEM_OMOP_DOMAIN_ID_MEASUREMENT).first_or_create
            schema_specific_naaccr_item_codes = true
          end
          table = seer_api.table(naaccr_schema.naaccr_staging_algorithm.algorithm, input['table'])

          table[:response]['rows'].each do |row|
            puts 'code'
            puts row.first
            puts 'code_description'
            puts row.last
            puts 'looking for snowflakes'
            puts naaccr_item.naaccr_item_codes.where("provenance = ? AND code = ? AND replace(lower(code_description), ' ', '') = ?", NaaccrItemCode::PROVENANCE_BASE_NAACCR_DATA_DICTIONARY, row.first, row.last.downcase).to_sql
            if naaccr_item.naaccr_item_codes.where("provenance = ? AND code = ? AND replace(lower(code_description), ' ', '') = ?", NaaccrItemCode::PROVENANCE_BASE_NAACCR_DATA_DICTIONARY, row.first, row.last.downcase.gsub(' ', '')).count == 0
              puts 'We found a snowflake.'
              schema_specific_naaccr_item_codes = true
            else
              puts 'We found a poser!'
            end
          end

          if schema_specific_naaccr_item_codes
            puts 'Schema specific NAACCR item codes!'

            if naaccr_item_site_specific.present?
              ni = naaccr_item_site_specific
            else
              ni = naaccr_item
            end

            table[:response]['rows'].each do |row|
              naaccr_item_code = NaaccrItemCode.where(naaccr_item_id: ni.id, code: row.first, code_description: row.last, code_omop_concept_code: "#{naaccr_schema.naaccr_staging_algorithm.algorithm}-#{naaccr_schema.seer_id}-#{naaccr_item.item_number}-#{row.first}", provenance: NaaccrItemCode::PROVENANCE_SEER_API, code_omop_domain_id: NaaccrItemCode::CODE_OMOP_DOMAIN_ID_MEAS_VALUE, code_standard_concept: 'S').first_or_create
              NaaccrSchemaMap.where(naaccr_schema: naaccr_schema, mappable: naaccr_item_code).first_or_create
            end
          else
            puts 'Same old NAACCR item codes!'
          end
        end
      end
      naaccr_schema.processed = true
      naaccr_schema.save!
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