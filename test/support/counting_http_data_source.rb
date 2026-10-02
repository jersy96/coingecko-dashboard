require_relative "fake_http_data_source"

class CountingHttpDataSource < FakeHttpDataSource
  def initialize
    @request_counts = Hash.new(0)
  end

  def get(path, query = {})
    @request_counts[path] += 1

    super
  end

  def request_count(path)
    @request_counts[path]
  end
end
