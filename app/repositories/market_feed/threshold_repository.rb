module MarketFeed
  class ThresholdRepository
    def all
      Result.try { MarketFeed::Threshold.all.to_a }
    end

    def find_or_prefill(metric)
      Result.try { find_or_build(metric) }
    end

    def upsert(metric:, alert_value:, good_value:)
      Result.try do
        threshold = MarketFeed::Threshold.find_or_initialize_by(metric: metric)
        threshold.update!(alert_value: alert_value, good_value: good_value)
        threshold
      end
    end

    private

    def find_or_build(metric)
      MarketFeed::Threshold.find_by(metric: metric) || build_default(metric)
    end

    def build_default(metric)
      MarketFeed::Threshold.new(metric: metric, **MarketFeed::Metrics.for(metric).default_values)
    end
  end
end
