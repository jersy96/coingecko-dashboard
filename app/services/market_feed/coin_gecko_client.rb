module MarketFeed
  class CoinGeckoClient
    BASE_URL = "https://api.coingecko.com/api/v3".freeze
    API_KEY_HEADER = "x-cg-demo-api-key".freeze
    RATE_LIMITED_STATUS = 429

    def initialize(http_data_source: self.class.default_http_data_source)
      @http_data_source = http_data_source
    end

    def self.default_http_data_source
      HttpDataSource.new(base_url: BASE_URL, headers: default_headers)
    end

    def self.default_headers
      api_key = ENV["COINGECKO_API_KEY"]
      return {} if api_key.blank?

      { API_KEY_HEADER => api_key }
    end

    def fetch_markets(coin_ids:, currency:)
      http_data_source.get("/coins/markets", {
        vs_currency: currency,
        ids: coin_ids.join(","),
        price_change_percentage: "24h"
      })
    end

    def fetch_top_markets(currency:, page_size:)
      http_data_source.get("/coins/markets", {
        vs_currency: currency,
        order: "market_cap_desc",
        per_page: page_size,
        page: 1
      })
    end

    def rate_limited?(error)
      error.try(:status) == RATE_LIMITED_STATUS
    end

    def fetch_supported_currencies
      http_data_source.get("/simple/supported_vs_currencies")
    end

    def search_coins(query:)
      http_data_source.get("/search", { query: query })
    end

    def fetch_simple_prices(coin_ids:, currencies:)
      http_data_source.get("/simple/price", {
        ids: coin_ids.join(","),
        vs_currencies: currencies.join(","),
        include_24hr_change: true
      })
    end

    def fetch_price_history(coin_id:, currency:, days:)
      http_data_source.get("/coins/#{coin_id}/market_chart", {
        vs_currency: currency,
        days: days,
        interval: "daily"
      })
    end

    private

    attr_reader :http_data_source
  end
end
