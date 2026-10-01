module MarketFeed
  class AssetCatalogController < ApplicationController
    requires_permission :view_market_feed

    def index
      catalog_result = MarketFeed::AssetCatalog.new.fetch(query: params[:query])
      return render json: { entries: [] }, status: :bad_gateway if catalog_result.failure?

      render json: { entries: catalog_result.data.map { |entry| { id: entry.id, label: entry.label } } }
    end
  end
end
