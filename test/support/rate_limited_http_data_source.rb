require_relative "fake_http_data_source"

require "ostruct"

class RateLimitedHttpDataSource < FakeHttpDataSource
  def initialize(rate_limited_paths:)
    @rate_limited_paths = rate_limited_paths
  end

  def get(path, query = {})
    return Result.failure(rate_limit_error) if rate_limited_paths.include?(path)

    super
  end

  private

  attr_reader :rate_limited_paths

  def rate_limit_error
    OpenStruct.new(message: "429 Too Many Requests", code: :http_error, status: 429, body: "")
  end
end
