module MarketFeed
  class ConversionRate
    attr_reader :currency, :price, :change_24h

    def initialize(currency:, price:, change_24h:)
      @currency = currency
      @price = price
      @change_24h = change_24h
    end
  end
end
