module MarketFeed
  class AssetHistoryController < ApplicationController
    include MarketFeed::ProviderFailureStatus

    requires_permission :view_market_feed

    def show
      history_result = asset_index.fetch_history(asset_id: params[:id])
      if history_result.failure?
        return render json: { points: [] }, status: provider_failure_status(history_result, asset_index)
      end

      render json: { points: history_result.data.map { |point| serialize(point) } }
    end

    private

    def serialize(price_point)
      { recorded_at: price_point.recorded_at.iso8601, price: price_point.price }
    end

    def asset_index
      @asset_index ||= MarketFeed::AssetIndex.new
    end
  end
end
