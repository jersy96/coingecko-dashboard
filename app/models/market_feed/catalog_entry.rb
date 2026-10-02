module MarketFeed
  class CatalogEntry
    attr_reader :id, :name, :symbol

    def initialize(id:, name:, symbol:)
      @id = id
      @name = name
      @symbol = symbol
    end

    def label
      "#{name} (#{id})"
    end
  end
end
