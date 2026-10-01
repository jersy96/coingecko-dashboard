module MarketFeed
  class CatalogEntry
    attr_reader :id, :name, :symbol

    def initialize(id:, name:, symbol:)
      @id = id
      @name = name
      @symbol = symbol
    end

    def label
      "#{name} (#{symbol})"
    end
  end
end
