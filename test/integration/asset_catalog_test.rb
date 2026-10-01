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
    assert_equal "Bitcoin (BTC)", entries.first["label"]
  end

  test "the catalog returns the search matches when a query is given" do
    get asset_catalog_path, params: { query: "sol" }

    assert_response :success
    entries = response.parsed_body["entries"]
    assert_equal [ "solana", "solar" ], entries.map { |entry| entry["id"] }
  end
end
