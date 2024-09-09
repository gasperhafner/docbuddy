module Api::Slack
  class Base < ::Api::Base
    DEFAULT_HEADERS = {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }.freeze

    def initialize(logger: Logging::RailsLogger.new, token: nil)
      url = base_url

      @conn = Faraday.new(url: url, headers: DEFAULT_HEADERS) do |faraday|
        faraday.request :retry, max: 2
        faraday.use Logging::FaradayMiddleware, logger: logger
        faraday.adapter Faraday.default_adapter
      end
    end

    def api_post(path, data = {})
      Rails.logger.debug "POST #{path}, data: #{data.to_json}"
      resp = conn.get(path, data)
      handle_resp(resp)
    rescue => e
      Rails.logger.error "POST ERROR #{e}, data: #{data.to_json}"
      raise e
    end

    private

    def base_url
      "https://slack.com/api/"
    end
  end
end
