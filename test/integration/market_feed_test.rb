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

  test "the requested currencies drive the conversion columns" do
    get root_path, params: { currencies: [ "jpy" ] }

    assert_response :success
    assert_select "th", text: "JPY"
    assert_select "th", text: "EUR", count: 0
  end
end
