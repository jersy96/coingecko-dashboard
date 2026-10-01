module MarketFeed
  class Threshold < ApplicationRecord
    self.table_name = "market_feed_thresholds"

    VOLATILITY_ALERT = "volatility_alert".freeze
    DAILY_CHANGE_ALERT = "daily_change_alert".freeze
    MARKET_CAP_FLOOR = "market_cap_floor".freeze

    ALERT = :alert
    GOOD = :good
    NEUTRAL = :neutral

    KINDS = {
      VOLATILITY_ALERT => {
        column: "24h Volatility",
        unit: "%",
        higher_is_worse: true,
        alert_value: 5.0,
        good_value: 2.0
      },
      DAILY_CHANGE_ALERT => {
        column: "Asset Price",
        unit: "%",
        higher_is_worse: true,
        alert_value: 10.0,
        good_value: 3.0
      },
      MARKET_CAP_FLOOR => {
        column: "Market Cap",
        unit: "USD",
        higher_is_worse: false,
        alert_value: 1_000_000_000.0,
        good_value: 50_000_000_000.0
      }
    }.freeze

    validates :kind, presence: true, uniqueness: true, inclusion: { in: KINDS.keys }
    validates :alert_value, numericality: { greater_than: 0 }, allow_nil: true
    validates :good_value, numericality: { greater_than: 0 }, allow_nil: true
    validate :at_least_one_value
    validate :bands_do_not_cross

    def self.default_values_for(kind)
      KINDS.fetch(kind).slice(:alert_value, :good_value)
    end

    def column
      KINDS.fetch(kind).fetch(:column)
    end

    def unit
      KINDS.fetch(kind).fetch(:unit)
    end

    def higher_is_worse?
      KINDS.fetch(kind).fetch(:higher_is_worse)
    end

    def status_for(asset)
      measurement = measurement_of(asset)
      return NEUTRAL if measurement.blank?
      return ALERT if alert_reached?(measurement)
      return GOOD if good_reached?(measurement)

      NEUTRAL
    end

    private

    def measurement_of(asset)
      case kind
      when VOLATILITY_ALERT then volatility_of(asset)
      when DAILY_CHANGE_ALERT then daily_change_of(asset)
      when MARKET_CAP_FLOOR then asset.market_cap
      end
    end

    def volatility_of(asset)
      return if asset.daily_range.blank?

      asset.daily_range * 100
    end

    def daily_change_of(asset)
      asset.conversion_rate_in(MarketFeed::Asset::BASE_CURRENCY)&.change_24h&.abs
    end

    def alert_reached?(measurement)
      return false if alert_value.blank?
      return measurement > alert_value if higher_is_worse?

      measurement < alert_value
    end

    def good_reached?(measurement)
      return false if good_value.blank?
      return measurement < good_value if higher_is_worse?

      measurement > good_value
    end

    def at_least_one_value
      return if alert_value.present? || good_value.present?

      errors.add(:base, "needs an alert value, a good value, or both")
    end

    def bands_do_not_cross
      return if alert_value.blank? || good_value.blank?
      return if higher_is_worse? ? good_value < alert_value : good_value > alert_value

      errors.add(:good_value, "must sit on the healthy side of the alert value")
    end
  end
end
