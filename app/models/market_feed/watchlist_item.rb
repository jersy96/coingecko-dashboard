module MarketFeed
  class WatchlistItem < ApplicationRecord
    self.table_name = "market_feed_watchlist_items"

    belongs_to :user

    validates :asset_id, presence: true, uniqueness: { scope: :user_id }
  end
end
