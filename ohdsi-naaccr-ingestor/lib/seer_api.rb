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