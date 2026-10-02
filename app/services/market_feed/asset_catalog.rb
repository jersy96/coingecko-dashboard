module MarketFeed
  class AssetCatalog
    PAGE_SIZE = 25

    def initialize(coin_gecko_client: MarketFeed::CoinGeckoClient.new)
      @coin_gecko_client = coin_gecko_client
    end

    def fetch(query: nil)
      return fetch_top_entries if query.blank?

      fetch_matching_entries(query)
    end

    def rate_limited?(error)
      coin_gecko_client.rate_limited?(error)
    end

    private

    attr_reader :coin_gecko_client

    def fetch_top_entries
      top_markets = coin_gecko_client.fetch_top_markets(
        currency: MarketFeed::Asset::BASE_CURRENCY,
        page_size: PAGE_SIZE
      )
      return top_markets if top_markets.failure?

      Result.success(build_entries(top_markets.data))
    end

    def fetch_matching_entries(query)
      matches = coin_gecko_client.search_coins(query: query)
      return matches if matches.failure?

      Result.success(build_entries(matches.data["coins"].first(PAGE_SIZE)))
    end

    def build_entries(raw_entries)
      raw_entries.map do |raw_entry|
        MarketFeed::CatalogEntry.new(
          id: raw_entry["id"],
          name: raw_entry["name"],
          symbol: raw_entry["symbol"].upcase
        )
      end
    end
  end
end
