class FakeHttpDataSource
  MARKET_ENTRIES = [
    { "id" => "bitcoin", "name" => "Bitcoin", "symbol" => "btc", "current_price" => 84_667.0, "price_change_percentage_24h" => 0.62, "high_24h" => 85_089.0, "low_24h" => 84_142.0, "market_cap" => 1_700_854_968_127 },
    { "id" => "ethereum", "name" => "Ethereum", "symbol" => "eth", "current_price" => 3_512.87, "price_change_percentage_24h" => 1.83, "high_24h" => 3_540.0, "low_24h" => 3_480.0, "market_cap" => 422_000_000_000 },
    { "id" => "solana", "name" => "Solana", "symbol" => "sol", "current_price" => 178.34, "price_change_percentage_24h" => 4.12, "high_24h" => 181.0, "low_24h" => 170.0, "market_cap" => 79_000_000_000 },
    { "id" => "cardano", "name" => "Cardano", "symbol" => "ada", "current_price" => 0.612, "price_change_percentage_24h" => -0.75, "high_24h" => 0.63, "low_24h" => 0.60, "market_cap" => 21_000_000_000 }
  ].freeze

  PRICE_HISTORY = {
    "prices" => [
      [ 1_789_948_800_000, 81_169.03 ],
      [ 1_790_035_200_000, 86_596.74 ],
      [ 1_790_121_600_000, 86_183.29 ]
    ]
  }.freeze

  CONVERSION_RATES = {
    "bitcoin" => { "usd" => 84_667.0, "usd_24h_change" => 0.62, "eur" => 74_376.0, "eur_24h_change" => 0.69, "gbp" => 63_960.0, "gbp_24h_change" => 0.72 },
    "ethereum" => { "usd" => 3_512.87, "usd_24h_change" => 1.83, "eur" => 3_085.0, "eur_24h_change" => 1.9, "gbp" => 2_653.0, "gbp_24h_change" => 1.95 },
    "solana" => { "usd" => 178.34, "usd_24h_change" => 4.12, "eur" => 156.6, "eur_24h_change" => 4.2, "gbp" => 134.7, "gbp_24h_change" => 4.25 },
    "cardano" => { "usd" => 0.612, "usd_24h_change" => -0.75, "eur" => 0.537, "eur_24h_change" => -0.7, "gbp" => 0.462, "gbp_24h_change" => -0.68 }
  }.freeze

  SEARCH_RESULTS = {
    "coins" => [
      { "id" => "solana", "name" => "Solana", "symbol" => "SOL" },
      { "id" => "solar", "name" => "Solar", "symbol" => "SXP" }
    ]
  }.freeze

  SUPPORTED_CURRENCIES = %w[usd eur gbp jpy brl].freeze

  def get(path, query = {})
    return Result.success(deep_dup_conversion_rates) if path == "/simple/price"
    return Result.success(SEARCH_RESULTS.dup) if path == "/search"
    return Result.success(SUPPORTED_CURRENCIES.dup) if path == "/simple/supported_vs_currencies"
    return Result.success(market_entries_for(query[:ids])) if path == "/coins/markets"
    return Result.success(MARKET_ENTRIES.map(&:dup)) if path == "/coins/markets"
    return Result.success(PRICE_HISTORY.dup) if path.end_with?("/market_chart")

    Result.failure(:unexpected_path)
  end

  private

  def market_entries_for(requested_ids)
    return MARKET_ENTRIES.map(&:dup) if requested_ids.blank?

    wanted = requested_ids.split(",")
    MARKET_ENTRIES.select { |entry| wanted.include?(entry["id"]) }.map(&:dup)
  end

  def deep_dup_conversion_rates
    CONVERSION_RATES.transform_values(&:dup)
  end
end
