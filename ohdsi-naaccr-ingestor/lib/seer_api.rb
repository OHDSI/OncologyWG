require 'rest_client'
class SeerApi
  ERROR_MESSAGE_DUPLICATE_PATIENT = 'More than one patient with record_id.'
  attr_accessor :api_key
  SYSTEM = 'seer'

  def self.initialize_seer_api
    seer_api = SeerApi.new(Rails.application.credentials.seer[Rails.env.to_sym][:api_key])
  end

  def initialize(api_key)
    @api_key = api_key
    if Rails.env.development? || Rails.env.test?
      @verify_ssl = Rails.application.credentials.seer[Rails.env.to_sym][:verify_ssl] || true
    else
      @verify_ssl = true
    end
  end

  def naaccr_versions
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:naaccr_versions_url]
    puts api_url

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def naaccr_items(version)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:naaccr_items_url]
    puts api_url
    api_url = api_url.gsub(':version', version)

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def naaccr_item(version, item_number)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:naaccr_item_url]
    puts api_url
    api_url = api_url.gsub(':version', version)
    api_url = api_url.gsub(':item_number', item_number.to_s)

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def surgery_titles
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:surgery_tables_url]
    puts api_url

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def surgery_title(title)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:surgery_table_url]
    api_url = "#{api_url}?title=#{title}"
    puts api_url

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def staging_algorithims
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:staging_algorithms_url]
    api_url = "#{api_url}"
    puts api_url

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def schemas(staging_algorithm)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:schemas_url]
    api_url = api_url.gsub(':algorithm', staging_algorithm)
    api_url = api_url.gsub(':version', 'latest')
    puts api_url

    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def schema(staging_algorithm, schema_id)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:schema_url]
    api_url = api_url.gsub(':algorithm', staging_algorithm)
    if staging_algorithm == 'eod_public'
      api_url = api_url.gsub(':version', '1.5')
    else
      api_url = api_url.gsub(':version', 'latest')
    end
    api_url = api_url.gsub(':schema_id', schema_id)
    puts api_url
    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  def table(staging_algorithm, table_id)
    api_url = Rails.application.credentials.seer[Rails.env.to_sym][:table_url]
    api_url = api_url.gsub(':algorithm', staging_algorithm)
    if staging_algorithm == 'eod_public'
      api_url = api_url.gsub(':version', '1.5')
    else
      api_url = api_url.gsub(':version', 'latest')
    end
    puts api_url
    api_url = api_url.gsub(':table_id', table_id.to_s)
    puts api_url
    api_response = seer_api_request_wrapper(api_url)

    { response: api_response[:response], error: api_response[:error] }
  end

  private
    def prepare_api_key_header
      api_key = Rails.application.credentials.seer[Rails.env.to_sym][:api_key]
      { 'X-SEERAPI-Key' => api_key }
    end

    def seer_api_request_wrapper(api_url, parse_response = true)
      response = nil
      error =  nil
      begin
        response = RestClient::Request.execute(
          method: :get,
          url: api_url,
          content_type:  'application/json',
          accept: 'json',
          verify_ssl: @verify_ssl,
          headers: prepare_api_key_header
        )
        # ApiLog.create_api_log(@api_url, payload, response, nil, RedcapApi::SYSTEM)
        response = JSON.parse(response) if parse_response
      rescue Exception => e
        # ExceptionNotifier.notify_exception(e)
        # ApiLog.create_api_log(@api_url, payload, nil, e.message, RedcapApi::SYSTEM)
        error = e
        Rails.logger.info(e.class)
        Rails.logger.info(e.message)
        Rails.logger.info(e.backtrace.join("\n"))
      end
      { response: response, error: error }
    end
end