require "test_helper"

class MarketFeedTest < ActionDispatch::IntegrationTest
  setup do
    post access_token_path, params: { user_id: users(:viewer).id }
  end

  test "the market feed section renders the asset rows, the metric selectors and the chart" do
    get root_path

    assert_response :success
    assert_select "section[data-controller=market-feed]" do
      assert_select "p", text: "Bitcoin"
      assert_select "p", text: "Ethereum"
      assert_select "p", text: "Solana"
      assert_select "p", text: "Cardano"

      assert_select "label", text: /Asset Price/
      assert_select "label", text: /24h Volatility/
      assert_select "label", text: /FX Conversion Rates/
      assert_select "label", text: /Market Cap/

      assert_select "input[type=checkbox][disabled]", count: 0
      assert_select "th", text: "24h Volatility"
      assert_select "th", text: "Market Cap"
      assert_select "th", text: "EUR"
      assert_select "th", text: "GBP"

      assert_select "canvas"
    end
  end

  test "the pickers render one search field each inside the shared form" do
    get root_path

    assert_response :success
    assert_select "form[data-controller=picker-form]" do
      assert_select "div[data-controller=asset-picker] input[type=search]"
      assert_select "div[data-controller=currency-picker] input[type=search]"
    end
  end

  test "a rate limited price lookup answers 429 and still renders the assets, with their conversion cells empty" do
    rate_limited = RateLimitedHttpDataSource.new(rate_limited_paths: [ "/simple/price" ])

    with_http_data_source(rate_limited) do
      get root_path
    end

    assert_response :too_many_requests
    assert_select "[data-controller=toast]", text: /rate limiting/
    assert_select "p", text: "Bitcoin"
    assert_select "p", text: "Cardano"
    assert_select "td[data-market-feed-target=conversionColumn]" do |cells|
      assert cells.any?, "expected the conversion columns to still be rendered"
      cells.each { |cell| assert_equal "", cell.text.strip }
    end
  end

  test "it caps the requested assets and currencies so one page cannot flood the provider" do
    many_assets = Array.new(30) { |index| "asset-#{index}" }
    many_currencies = Array.new(30) { |index| "currency-#{index}" }

    get root_path, params: { asset_ids: many_assets, currencies: many_currencies }

    assert_response :success
    assert_operator css_select("tbody tr").size, :<=, MarketFeed::AssetIndex::MAX_ASSETS
    assert_operator css_select("thead th[data-market-feed-target=conversionColumn]").size,
                    :<=,
                    MarketFeed::AssetIndex::MAX_CURRENCIES
  end

  test "a rate limited feed keeps the requested selection in the pickers" do
    rate_limited = RateLimitedHttpDataSource.new(rate_limited_paths: [ "/coins/markets" ])

    with_http_data_source(rate_limited) do
      get root_path, params: { asset_ids: [ "bitcoin", "solana" ], currencies: [ "jpy" ] }
    end

    assert_response :too_many_requests
    assert_select "div[data-controller=asset-picker][data-asset-picker-selected-value=?]",
                  [ "bitcoin", "solana" ].to_json
    assert_select "div[data-controller=currency-picker][data-currency-picker-selected-value=?]",
                  [ "usd", "jpy" ].to_json
  end

  test "the requested currencies drive the conversion columns" do
    get root_path, params: { currencies: [ "jpy" ] }

    assert_response :success
    assert_select "th", text: "JPY"
    assert_select "th", text: "EUR", count: 0
  end
end
