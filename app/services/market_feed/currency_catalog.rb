module MarketFeed
  class CurrencyCatalog
    TTL_SECONDS = 24.hours.to_i

    def initialize(
      coin_gecko_client: MarketFeed::CoinGeckoClient.new,
      cache_data_source: CacheDataSource.new(namespace: "currency_catalog")
    )
      @coin_gecko_client = coin_gecko_client
      @cache_data_source = cache_data_source
    end

    def fetch
      supported_currencies = cached_supported_currencies
      return supported_currencies if supported_currencies.failure?

      Result.success(supported_currencies.data.sort)
    end

    def rate_limited?(error)
      coin_gecko_client.rate_limited?(error)
    end

    private

    attr_reader :coin_gecko_client, :cache_data_source

    def cached_supported_currencies
      cache_data_source.fetch(
        key: "supported",
        ttl_seconds: TTL_SECONDS,
        serve_stale_if: ->(error) { rate_limited?(error) }
      ) { coin_gecko_client.fetch_supported_currencies }
    end
  end
end
