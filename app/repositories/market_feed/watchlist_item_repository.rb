module MarketFeed
  class WatchlistItemRepository
    def all_for(user)
      Result.try { items_for(user).to_a }
    end

    def asset_ids_for(user)
      Result.try { items_for(user).pluck(:asset_id) }
    end

    def includes?(user:, asset_id:)
      Result.try { items_for(user).exists?(asset_id: asset_id) }
    end

    def add(user:, asset_id:)
      Result.try { items_for(user).find_or_create_by!(asset_id: asset_id) }
    end

    def remove(user:, asset_id:)
      Result.try { items_for(user).where(asset_id: asset_id).destroy_all }
    end

    private

    def items_for(user)
      MarketFeed::WatchlistItem.where(user: user).order(:created_at)
    end
  end
end
