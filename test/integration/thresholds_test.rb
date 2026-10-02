require "test_helper"

class ThresholdsTest < ActionDispatch::IntegrationTest
  setup do
    post access_token_path, params: { user_id: users(:admin).id }
  end

  test "an admin saves a threshold and it is recorded in the activity log" do
    patch threshold_path(MarketFeed::Metrics::VOLATILITY_ALERT), params: { alert_value: 1, good_value: 0.5 }

    assert_redirected_to thresholds_path
    assert_equal 1.0, MarketFeed::Threshold.find_by(metric: "volatility_alert").alert_value

    get activity_entries_path

    assert_select "td", text: "Threshold updated"
  end

  test "crossed bands are rejected with a message" do
    patch threshold_path(MarketFeed::Metrics::VOLATILITY_ALERT), params: { alert_value: 5, good_value: 8 }

    assert_redirected_to thresholds_path
    assert_match "healthy side", flash[:alert]
    assert_nil MarketFeed::Threshold.find_by(metric: "volatility_alert")
  end

  test "a breached threshold paints the volatility cell" do
    patch threshold_path(MarketFeed::Metrics::VOLATILITY_ALERT), params: { alert_value: 0.1, good_value: 0.05 }

    get root_path

    assert_response :success
    assert_select "td[data-market-feed-target=volatilityColumn].bg-red-50"
  end

  test "a trader cannot reach the thresholds page" do
    reset!
    post access_token_path, params: { user_id: users(:trader).id }

    get thresholds_path

    assert_response :forbidden
  end

  test "a trader sees no thresholds link" do
    reset!
    post access_token_path, params: { user_id: users(:trader).id }

    get root_path

    assert_response :success
    assert_select "a", text: "Thresholds", count: 0
  end
end
