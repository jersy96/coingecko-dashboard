module Authorization
  class Permissions
    ALLOWED_BY_ROLE = {
      "viewer" => %i[view_market_feed].freeze,
      "trader" => %i[view_market_feed manage_own_watchlist].freeze
    }.freeze

    def allows?(user:, permission:)
      return false if user.blank?
      return true if user.admin?

      ALLOWED_BY_ROLE.fetch(user.role, []).include?(permission)
    end
  end
end
