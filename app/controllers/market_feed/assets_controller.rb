module MarketFeed
  class AssetsController < ApplicationController
    requires_permission :view_market_feed

    def index
      asset_index_result = MarketFeed::AssetIndex.new.fetch(
        asset_ids: params[:asset_ids],
        currencies: params[:currencies],
        user: watchlist_owner,
        selected_asset_id: params[:selected_asset_id]
      )
      report_failure(asset_index_result) if asset_index_result.failure?

      @market_feed_assets = asset_index_result.data&.assets || []
      @selected_currencies = asset_index_result.data&.currencies || []
      @supported_currencies = fetch_supported_currencies
      @watched_asset_ids = asset_index_result.data&.watched_asset_ids || []
      @threshold_statuses = asset_index_result.data&.threshold_statuses || {}
    end

    private

    def watchlist_owner
      return unless allowed_to?(:manage_own_watchlist)

      Current.user
    end

    def fetch_supported_currencies
      supported_currencies = MarketFeed::CurrencyCatalog.new.fetch
      return report_failure_and_discard(supported_currencies) if supported_currencies.failure?

      supported_currencies.data
    end

    def report_failure_and_discard(result)
      report_failure(result)

      []
    end
  end
end
