module MarketFeed
  module Metrics
    VOLATILITY_ALERT = "volatility_alert".freeze
    DAILY_CHANGE_ALERT = "daily_change_alert".freeze
    MARKET_CAP_FLOOR = "market_cap_floor".freeze

    ALL = [
      Metric.new(
        key: VOLATILITY_ALERT,
        unit: "%",
        higher_is_worse: true,
        alert_default: 5.0,
        good_default: 2.0
      ),
      Metric.new(
        key: DAILY_CHANGE_ALERT,
        unit: "%",
        higher_is_worse: true,
        alert_default: 10.0,
        good_default: 3.0
      ),
      Metric.new(
        key: MARKET_CAP_FLOOR,
        unit: "USD",
        higher_is_worse: false,
        alert_default: 1_000_000_000.0,
        good_default: 50_000_000_000.0
      )
    ].freeze

    def self.keys
      ALL.map(&:key)
    end

    def self.for(key)
      ALL.find { |metric| metric.key == key }
    end
  end
end
