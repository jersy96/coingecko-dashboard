require "test_helper"

class AssetHistoryTest < ActionDispatch::IntegrationTest
  setup do
    post access_token_path, params: { user_id: users(:viewer).id }
  end

  test "it answers the price points of a single asset" do
    get asset_history_path(id: "bitcoin")

    assert_response :success
    points = response.parsed_body["points"]
    assert_equal 3, points.size
    assert_equal 81_169.03, points.first["price"]
    assert points.first["recorded_at"].present?
  end

  test "a rate limited provider answers 429 so the dashboard can tell it apart from no data" do
    rate_limited = RateLimitedHttpDataSource.new(rate_limited_paths: [ "/coins/bitcoin/market_chart" ])

    with_http_data_source(rate_limited) do
      get asset_history_path(id: "bitcoin")
    end

    assert_response :too_many_requests
    assert_equal [], response.parsed_body["points"]
  end

  test "it refuses an anonymous request" do
    reset!

    get asset_history_path(id: "bitcoin"), as: :json

    assert_response :unauthorized
  end
end
