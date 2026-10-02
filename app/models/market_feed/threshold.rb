module MarketFeed
  class Threshold < ApplicationRecord
    self.table_name = "market_feed_thresholds"

    ALERT = :alert
    GOOD = :good
    NEUTRAL = :neutral

    validates :metric, presence: true, uniqueness: true, inclusion: { in: Metrics.keys }
    validates :alert_value, numericality: { greater_than: 0 }, allow_nil: true
    validates :good_value, numericality: { greater_than: 0 }, allow_nil: true
    validate :at_least_one_value
    validate :bands_do_not_cross

    def unit
      metric_definition.unit
    end

    def higher_is_worse?
      metric_definition.higher_is_worse?
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
      case metric
      when Metrics::VOLATILITY_ALERT then asset.volatility_percent
      when Metrics::DAILY_CHANGE_ALERT then asset.daily_change_percent
      when Metrics::MARKET_CAP_FLOOR then asset.market_cap
      end
    end

    def metric_definition
      Metrics.for(metric)
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
