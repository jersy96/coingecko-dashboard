class RenameKindToMetricOnMarketFeedThresholds < ActiveRecord::Migration[8.1]
  def change
    rename_column :market_feed_thresholds, :kind, :metric
  end
end
