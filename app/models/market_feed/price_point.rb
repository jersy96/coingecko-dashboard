module MarketFeed
  class PricePoint
    attr_reader :recorded_at, :price

    def initialize(recorded_at:, price:)
      @recorded_at = recorded_at
      @price = price
    end
  end
end
