module MarketFeed
  class WatchlistItemsController < ApplicationController
    requires_permission :manage_own_watchlist

    before_action :enforce_owner_scope

    def index
      watched_items = watchlist_item_repository.all_for(watchlist_owner)
      @watched_items = watched_items.failure? ? report_failure_and_discard(watched_items) : watched_items.data
      @watchlist_owner = watchlist_owner
    end

    def create
      added_item = watchlist_item_repository.add(user: watchlist_owner, asset_id: params[:asset_id])
      report_failure(added_item) if added_item.failure?
      record_activity("watchlist_item.added", params[:asset_id]) if added_item.success?

      redirect_to watchlist_items_path(owner_scope)
    end

    def destroy
      removed_items = watchlist_item_repository.remove(user: watchlist_owner, asset_id: params[:id])
      report_failure(removed_items) if removed_items.failure?
      record_activity("watchlist_item.removed", params[:id]) if removed_items.success?

      redirect_to watchlist_items_path(owner_scope)
    end

    private

    def record_activity(action, asset_id)
      Auditing::ActivityEntryCreate.new.call(
        user: Current.user,
        action: action,
        subject: asset_id,
        details: { watchlist_owner_id: watchlist_owner.id }
      )
    end

    def enforce_owner_scope
      return if requested_owner_id.blank?
      return if allowed_to?(:manage_any_watchlist)

      head :forbidden
    end

    def watchlist_owner
      return Current.user if requested_owner_id.blank?

      @watchlist_owner ||= User.find_by(id: requested_owner_id)
    end

    def requested_owner_id
      params[:user_id]
    end

    def owner_scope
      return {} if requested_owner_id.blank?

      { user_id: requested_owner_id }
    end

    def watchlist_item_repository
      @watchlist_item_repository ||= MarketFeed::WatchlistItemRepository.new
    end

    def report_failure_and_discard(result)
      report_failure(result)

      []
    end
  end
end
