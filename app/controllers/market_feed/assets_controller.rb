module MarketFeed
  class AssetsController < ApplicationController
    requires_permission :view_market_feed

    def index
      asset_index_result = asset_index.fetch(
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

      render status: :too_many_requests if rate_limited?(asset_index_result)
    end

    private

    def rate_limited?(asset_index_result)
      return true if asset_index_result.data&.rate_limited
      return false unless asset_index_result.failure?

      asset_index.rate_limited?(asset_index_result.error)
    end

    def watchlist_owner
      return unless allowed_to?(:manage_own_watchlist)

      Current.user
    end

    def fetch_supported_currencies
      supported_currencies = MarketFeed::CurrencyCatalog.new.fetch
      return report_failure_and_discard(supported_currencies) if supported_currencies.failure?

      supported_currencies.data
    end

    def asset_index
      @asset_index ||= MarketFeed::AssetIndex.new
    end

    def report_failure_and_discard(result)
      report_failure(result)

      []
    end
  end
end
