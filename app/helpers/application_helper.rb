module ApplicationHelper
  THRESHOLD_CELL_CLASSES = {
    alert: "bg-red-50 font-medium text-red-700 transition group-hover:bg-red-100",
    good: "bg-emerald-50 font-medium text-emerald-700 transition group-hover:bg-emerald-100"
  }.freeze

  THRESHOLD_COLUMN_LABELS = {
    MarketFeed::Metrics::VOLATILITY_ALERT => "24h Volatility",
    MarketFeed::Metrics::DAILY_CHANGE_ALERT => "Asset Price",
    MarketFeed::Metrics::MARKET_CAP_FLOOR => "Market Cap"
  }.freeze

  def threshold_cell_classes(threshold_statuses, asset, metric)
    status = threshold_statuses.dig(asset.id, metric)

    THRESHOLD_CELL_CLASSES.fetch(status, "text-slate-700")
  end

  def threshold_column_label(metric)
    THRESHOLD_COLUMN_LABELS.fetch(metric)
  end
end
