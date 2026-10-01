class CreateMarketFeedWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :market_feed_watchlist_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :asset_id, null: false

      t.timestamps
    end

    add_index :market_feed_watchlist_items, [ :user_id, :asset_id ], unique: true
  end
end
