module MarketFeed
  class ThresholdRepository
    def all
      Result.try { MarketFeed::Threshold.all.to_a }
    end

    def find_or_prefill(kind)
      Result.try { find_or_build(kind) }
    end

    def upsert(kind:, alert_value:, good_value:)
      Result.try do
        threshold = MarketFeed::Threshold.find_or_initialize_by(kind: kind)
        threshold.update!(alert_value: alert_value, good_value: good_value)
        threshold
      end
    end

    private

    def find_or_build(kind)
      MarketFeed::Threshold.find_by(kind: kind) || build_default(kind)
    end

    def build_default(kind)
      MarketFeed::Threshold.new(kind: kind, **MarketFeed::Threshold.default_values_for(kind))
    end
  end
end
