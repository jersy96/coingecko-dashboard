require "ostruct"

module MarketFeed
  class AssetIndex
    DEFAULT_ASSET_IDS = %w[bitcoin ethereum solana cardano].freeze
    DEFAULT_CURRENCIES = %w[usd eur gbp].freeze
    HISTORY_DAYS = 7
    PRICES_TTL_SECONDS = 60
    MAX_ASSETS = 10
    MAX_CURRENCIES = 10

    def initialize(
      coin_gecko_client: MarketFeed::CoinGeckoClient.new,
      cache_data_source: CacheDataSource.new(namespace: "market_feed"),
      watchlist_item_repository: MarketFeed::WatchlistItemRepository.new,
      threshold_repository: MarketFeed::ThresholdRepository.new
    )
      @coin_gecko_client = coin_gecko_client
      @cache_data_source = cache_data_source
      @watchlist_item_repository = watchlist_item_repository
      @threshold_repository = threshold_repository
    end

    def fetch(asset_ids: nil, currencies: nil, user: nil, selected_asset_id: nil)
      @rate_limited = false
      watched_asset_ids = watchlist_asset_ids(user)
      requested_asset_ids = resolve_asset_ids(asset_ids, watched_asset_ids)
      requested_currencies = resolve_currencies(currencies)

      markets = fetch_markets(requested_asset_ids)
      return markets if markets.failure?

      conversion_rates = fetch_simple_prices(requested_asset_ids, requested_currencies)
      return conversion_rates if conversion_rates.failure?

      build_assets(
        markets.data,
        conversion_rates.data,
        requested_asset_ids,
        requested_currencies,
        watched_asset_ids,
        selected_asset_id
      )
    end

    def fetch_history(asset_id:)
      market_chart = cached(price_history_cache_key(asset_id)) { request_price_history(asset_id) }
      return market_chart if market_chart.failure?

      Result.success(build_price_points(market_chart.data["prices"]))
    end

    def rate_limited?(error)
      coin_gecko_client.rate_limited?(error)
    end

    private

    attr_reader :coin_gecko_client, :cache_data_source, :watchlist_item_repository, :threshold_repository

    def fetch_markets(coin_ids)
      cached_with_fallback("markets:#{coin_ids.join(",")}:#{MarketFeed::Asset::BASE_CURRENCY}", fallback: []) do
        coin_gecko_client.fetch_markets(coin_ids: coin_ids, currency: MarketFeed::Asset::BASE_CURRENCY)
      end
    end

    def fetch_simple_prices(coin_ids, currencies)
      cached_with_fallback("simple_prices:#{coin_ids.join(",")}:#{currencies.join(",")}", fallback: {}) do
        coin_gecko_client.fetch_simple_prices(coin_ids: coin_ids, currencies: currencies)
      end
    end

    def cached(cache_key, &fetch_from_provider)
      cache_data_source.fetch(
        key: cache_key,
        ttl_seconds: PRICES_TTL_SECONDS,
        serve_stale_if: ->(error) { coin_gecko_client.rate_limited?(error) },
        &fetch_from_provider
      )
    end

    def cached_with_fallback(cache_key, fallback:, &fetch_from_provider)
      cached_payload = cached(cache_key, &fetch_from_provider)
      return cached_payload unless rate_limited_without_cache?(cached_payload)

      @rate_limited = true
      Result.success(fallback)
    end

    def rate_limited_without_cache?(cached_payload)
      cached_payload.failure? && coin_gecko_client.rate_limited?(cached_payload.error)
    end

    def resolve_asset_ids(asset_ids, watched_asset_ids)
      return Array(asset_ids).reject(&:blank?).first(MAX_ASSETS) if asset_ids.present?

      (watched_asset_ids.presence || DEFAULT_ASSET_IDS).first(MAX_ASSETS)
    end

    def watchlist_asset_ids(user)
      return [] if user.blank?

      watched_asset_ids = watchlist_item_repository.asset_ids_for(user)
      return [] if watched_asset_ids.failure?

      watched_asset_ids.data
    end

    def resolve_currencies(currencies)
      return DEFAULT_CURRENCIES if currencies.blank?

      ([ MarketFeed::Asset::BASE_CURRENCY ] + Array(currencies).reject(&:blank?)).uniq.first(MAX_CURRENCIES)
    end

    def build_assets(market_entries, conversion_rate_entries, requested_asset_ids, currencies, watched_asset_ids, selected_asset_id)
      charted_asset_id = resolve_selected_asset_id(market_entries, selected_asset_id)

      assets = market_entries.map do |market_entry|
        asset = build_asset(
          market_entry,
          conversion_rate_entries.fetch(market_entry["id"], {}),
          currencies,
          market_entry["id"] == charted_asset_id
        )
        return asset if asset.failure?

        asset.data
      end

      Result.success(
        OpenStruct.new(
          assets: assets,
          currencies: quoted_currencies(assets),
          requested_asset_ids: requested_asset_ids,
          requested_currencies: currencies,
          watched_asset_ids: watched_asset_ids,
          threshold_statuses: threshold_statuses(assets),
          rate_limited: @rate_limited
        )
      )
    end

    def threshold_statuses(assets)
      thresholds = fetch_thresholds

      assets.index_by(&:id).transform_values do |asset|
        thresholds.index_by(&:metric).transform_values { |threshold| threshold.status_for(asset) }
      end
    end

    def fetch_thresholds
      thresholds = threshold_repository.all
      return [] if thresholds.failure?

      thresholds.data
    end

    def quoted_currencies(assets)
      return [] if assets.empty?

      assets.first.conversion_rates.map(&:currency)
    end

    def resolve_selected_asset_id(market_entries, selected_asset_id)
      return selected_asset_id if market_entries.any? { |market_entry| market_entry["id"] == selected_asset_id }

      market_entries.first&.fetch("id", nil)
    end

    def build_asset(market_entry, conversion_rate_entry, currencies, charted)
      price_history = charted ? fetch_price_history(market_entry["id"]) : Result.success([])
      return price_history if price_history.failure?

      Result.success(
        MarketFeed::Asset.new(
          id: market_entry["id"],
          name: market_entry["name"],
          symbol: market_entry["symbol"].upcase,
          conversion_rates: build_conversion_rates(conversion_rate_entry, currencies),
          price_history: price_history.data,
          high_24h: market_entry["high_24h"],
          low_24h: market_entry["low_24h"],
          market_cap: market_entry["market_cap"]
        )
      )
    end

    def build_conversion_rates(conversion_rate_entry, currencies)
      currencies.map do |currency|
        MarketFeed::ConversionRate.new(
          currency: currency,
          price: conversion_rate_entry[currency],
          change_24h: conversion_rate_entry["#{currency}_24h_change"]
        )
      end
    end

    def fetch_price_history(asset_id)
      market_chart = cached_with_fallback(price_history_cache_key(asset_id), fallback: { "prices" => [] }) do
        request_price_history(asset_id)
      end
      return market_chart if market_chart.failure?

      Result.success(build_price_points(market_chart.data["prices"]))
    end

    def price_history_cache_key(asset_id)
      "price_history:#{asset_id}:#{MarketFeed::Asset::BASE_CURRENCY}:#{HISTORY_DAYS}"
    end

    def request_price_history(asset_id)
      coin_gecko_client.fetch_price_history(
        coin_id: asset_id,
        currency: MarketFeed::Asset::BASE_CURRENCY,
        days: HISTORY_DAYS
      )
    end

    def build_price_points(prices)
      prices.map do |recorded_at_in_milliseconds, price|
        MarketFeed::PricePoint.new(
          recorded_at: Time.zone.at(recorded_at_in_milliseconds / 1000),
          price: price
        )
      end
    end
  end
end
