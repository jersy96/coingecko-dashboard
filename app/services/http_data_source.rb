require "net/http"
require "ostruct"

class HttpDataSource
  READ_TIMEOUT_SECONDS = 10
  OPEN_TIMEOUT_SECONDS = 5

  def initialize(base_url:, headers: {})
    @base_url = base_url
    @headers = headers
  end

  def get(path, query = {})
    response = perform_request(build_uri(path, query))
    return Result.failure(response_error(response)) unless response.is_a?(Net::HTTPSuccess)

    Result.success(JSON.parse(response.body))
  rescue Net::OpenTimeout, Net::ReadTimeout => exception
    Result.failure(transport_error(:timeout, exception))
  rescue SocketError, SystemCallError => exception
    Result.failure(transport_error(:unreachable, exception))
  rescue JSON::ParserError => exception
    Result.failure(transport_error(:malformed_response, exception))
  end

  private

  attr_reader :base_url, :headers

  def response_error(response)
    Rails.logger.warn("[HttpDataSource] #{response.code} #{response.message} #{base_url}")

    OpenStruct.new(
      message: "#{response.code} #{response.message}",
      code: :http_error,
      status: response.code.to_i,
      body: response.body
    )
  end

  def transport_error(code, exception)
    OpenStruct.new(message: exception.message, code: code, status: nil, body: nil)
  end

  def build_uri(path, query)
    uri = URI.parse("#{base_url}#{path}")
    uri.query = URI.encode_www_form(query) if query.any?
    uri
  end

  def perform_request(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: OPEN_TIMEOUT_SECONDS,
      read_timeout: READ_TIMEOUT_SECONDS
    ) { |http| http.request(Net::HTTP::Get.new(uri, headers)) }
  end
end
