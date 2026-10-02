require "test_helper"

class AssetCatalogTest < ActionDispatch::IntegrationTest
  setup do
    post access_token_path, params: { user_id: users(:viewer).id }
  end

  test "the catalog returns the default entries when no query is given" do
    get asset_catalog_path

    assert_response :success
    entries = response.parsed_body["entries"]
    assert_equal 4, entries.size
    assert_equal "bitcoin", entries.first["id"]
    assert_equal "Bitcoin (bitcoin)", entries.first["label"]
  end

  test "a rate limited provider answers 429 instead of a generic gateway error" do
    rate_limited = RateLimitedHttpDataSource.new(rate_limited_paths: [ "/coins/markets" ])

    with_http_data_source(rate_limited) do
      get asset_catalog_path
    end

    assert_response :too_many_requests
    assert_equal [], response.parsed_body["entries"]
  end

  test "the catalog returns the search matches when a query is given" do
    get asset_catalog_path, params: { query: "sol" }

    assert_response :success
    entries = response.parsed_body["entries"]
    assert_equal [ "solana", "solar" ], entries.map { |entry| entry["id"] }
  end
end
