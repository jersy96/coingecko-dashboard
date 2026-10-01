class CreateMarketFeedThresholds < ActiveRecord::Migration[8.1]
  def change
    create_table :market_feed_thresholds do |t|
      t.string :kind, null: false
      t.decimal :alert_value, precision: 20, scale: 4
      t.decimal :good_value, precision: 20, scale: 4

      t.timestamps
    end

    add_index :market_feed_thresholds, :kind, unique: true
  end
end
