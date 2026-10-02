module MarketFeed
  class AssetHistoryController < ApplicationController
    requires_permission :view_market_feed

    def show
      history_result = MarketFeed::AssetIndex.new.fetch_history(asset_id: params[:id])
      return render json: { points: [] }, status: :bad_gateway if history_result.failure?

      render json: { points: history_result.data.map { |point| serialize(point) } }
    end

    private

    def serialize(price_point)
      { recorded_at: price_point.recorded_at.iso8601, price: price_point.price }
    end
  end
end
