module Api::Slack
  class Webhook < Base
    def initialize(logger: Logging::RailsLogger.new, webhook_url: nil, token: nil)
      @conn = Faraday.new(url: webhook_url, headers: DEFAULT_HEADERS) do |faraday|
        faraday.request :retry, max: 2
        faraday.use Logging::FaradayMiddleware, logger: logger
        faraday.adapter Faraday.default_adapter
      end
    end

    def create(data)
      resp = @conn.post do |req|
        req.body = data.to_json
      end
      handle_resp(resp)
    rescue => e
      # in case of error, we want to log it and continue
      Sentry.capture_exception(e)
    end

    def handle_resp(resp)
      @response_body = resp.body.presence ? resp.body : nil
      @response_code = resp.status

      case resp.status
      when 200..299
        @response_body
      when 404
        raise Api::NotFoundError.new(resp), "Resource not found: #{resp.body}, headers: #{resp.headers.to_s}"
      when 400..499
        raise Api::ClientError.new(resp), "Server returned #{resp.status}: #{resp.body}, headers: #{resp.headers.to_s}"
      when 500..599
        raise Api::ServerError.new(resp), "Server returned #{resp.status}: #{resp.body}, headers: #{resp.headers.to_s}"
      else
        raise Api::Error.new(resp), "Server returned #{resp.status}: #{resp.body}, headers: #{resp.headers.to_s}"
      end

    rescue JSON::ParserError => e
      raise Api::ServerError.new(resp), "Server returned #{resp.status}: #{resp.body}, headers: #{resp.headers.to_s}"
    end
  end
end
