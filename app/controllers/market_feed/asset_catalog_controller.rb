module MarketFeed
  class AssetCatalogController < ApplicationController
    include MarketFeed::ProviderFailureStatus

    requires_permission :view_market_feed

    def index
      catalog_result = asset_catalog.fetch(query: params[:query])
      if catalog_result.failure?
        return render json: { entries: [] }, status: provider_failure_status(catalog_result, asset_catalog)
      end

      render json: { entries: catalog_result.data.map { |entry| { id: entry.id, label: entry.label } } }
    end

    private

    def asset_catalog
      @asset_catalog ||= MarketFeed::AssetCatalog.new
    end
  end
end
