module MarketFeed
  class Metric
    attr_reader :key, :unit, :alert_default, :good_default

    def initialize(key:, unit:, higher_is_worse:, alert_default:, good_default:)
      @key = key
      @unit = unit
      @higher_is_worse = higher_is_worse
      @alert_default = alert_default
      @good_default = good_default
    end

    def higher_is_worse?
      @higher_is_worse
    end

    def default_values
      { alert_value: alert_default, good_value: good_default }
    end
  end
end
