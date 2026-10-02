module MarketFeed
  class CurrencyCatalog
    def initialize(coin_gecko_client: MarketFeed::CoinGeckoClient.new)
      @coin_gecko_client = coin_gecko_client
    end

    def fetch
      supported_currencies = coin_gecko_client.fetch_supported_currencies
      return supported_currencies if supported_currencies.failure?

      Result.success(supported_currencies.data.sort)
    end

    def rate_limited?(error)
      coin_gecko_client.rate_limited?(error)
    end

    private

    attr_reader :coin_gecko_client
  end
end
