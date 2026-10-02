ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

Dir[Rails.root.join("test/support/**/*.rb")].each { |support_file| require support_file }

module CoinGeckoClientTestDataSource
  attr_accessor :overridden_http_data_source

  def default_http_data_source
    overridden_http_data_source || FakeHttpDataSource.new
  end
end

MarketFeed::CoinGeckoClient.singleton_class.prepend(CoinGeckoClientTestDataSource)

module ActiveSupport
  class TestCase
    def with_http_data_source(http_data_source)
      MarketFeed::CoinGeckoClient.overridden_http_data_source = http_data_source
      yield
    ensure
      MarketFeed::CoinGeckoClient.overridden_http_data_source = nil
    end
  end
end
