require "test_helper"

module MarketFeed
  class AssetCatalogTest < ActiveSupport::TestCase
    test "it asks the provider once and serves the second call from the cache" do
      counting = CountingHttpDataSource.new
      catalog = build_catalog(counting)

      first = catalog.fetch
      second = catalog.fetch

      assert first.success?
      assert_equal first.data.map(&:id), second.data.map(&:id)
      assert_equal 1, counting.request_count("/coins/markets")
    end

    test "it caches each query separately" do
      counting = CountingHttpDataSource.new
      catalog = build_catalog(counting)

      catalog.fetch(query: "sol")
      catalog.fetch(query: "sol")

      assert_equal 1, counting.request_count("/search")
    end

    private

    def build_catalog(http_data_source)
      MarketFeed::AssetCatalog.new(
        coin_gecko_client: MarketFeed::CoinGeckoClient.new(http_data_source: http_data_source),
        cache_data_source: CacheDataSource.new(namespace: "asset_catalog", store: ActiveSupport::Cache::MemoryStore.new)
      )
    end
  end
end
