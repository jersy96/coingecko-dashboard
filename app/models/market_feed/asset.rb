module MarketFeed
  class Asset
    BASE_CURRENCY = "usd".freeze

    attr_reader :id, :name, :symbol, :conversion_rates, :price_history, :high_24h, :low_24h, :market_cap

    def initialize(id:, name:, symbol:, conversion_rates:, price_history:, high_24h:, low_24h:, market_cap:)
      @id = id
      @name = name
      @symbol = symbol
      @conversion_rates = conversion_rates
      @price_history = price_history
      @high_24h = high_24h
      @low_24h = low_24h
      @market_cap = market_cap
    end

    def current_price
      base_conversion_rate&.price
    end

    def conversion_rate_in(currency)
      conversion_rates.find { |conversion_rate| conversion_rate.currency == currency }
    end

    def price_history_values
      price_history.map(&:price)
    end

    def daily_range
      return if low_24h.blank? || low_24h.zero?

      (high_24h - low_24h) / low_24h.to_f
    end

    def volatility_percent
      return if daily_range.blank?

      daily_range * 100
    end

    def daily_change_percent
      base_conversion_rate&.change_24h&.abs
    end

    private

    def base_conversion_rate
      conversion_rate_in(BASE_CURRENCY)
    end
  end
end
