require "test_helper"

class WatchlistTest < ActionDispatch::IntegrationTest
  setup do
    @trader = users(:trader)
    post access_token_path, params: { user_id: @trader.id }
  end

  test "an asset added from the market feed shows up on the watchlist page" do
    post watchlist_items_path, params: { asset_id: "polkadot" }

    get watchlist_items_path

    assert_response :success
    assert_select "td", text: "Polkadot"
  end

  test "adding the same asset twice keeps a single entry" do
    post watchlist_items_path, params: { asset_id: "polkadot" }
    post watchlist_items_path, params: { asset_id: "polkadot" }

    assert_equal 1, MarketFeed::WatchlistItem.where(user: @trader).count
  end

  test "a removed asset disappears from the watchlist page" do
    post watchlist_items_path, params: { asset_id: "polkadot" }
    delete watchlist_item_path("polkadot")

    get watchlist_items_path

    assert_response :success
    assert_select "td", text: "Polkadot", count: 0
  end

  test "the market feed opens with the watched assets instead of the defaults" do
    post watchlist_items_path, params: { asset_id: "solana" }

    get root_path

    assert_response :success
    assert_select "section[data-controller=market-feed]" do
      assert_select "p", text: "Solana"
      assert_select "p", text: "Bitcoin", count: 0
    end
  end

  test "the watchlist page sends a signed out visitor to the sign in page" do
    reset!

    get watchlist_items_path

    assert_redirected_to sign_in_path
  end

  test "a json request from a signed out visitor answers 401" do
    reset!

    get asset_catalog_path, as: :json

    assert_response :unauthorized
  end

  test "the watchlist page answers 403 to a viewer" do
    reset!
    post access_token_path, params: { user_id: users(:viewer).id }

    get watchlist_items_path

    assert_response :forbidden
  end

  test "an admin reaches the watchlist page" do
    reset!
    post access_token_path, params: { user_id: users(:admin).id }

    get watchlist_items_path

    assert_response :success
  end

  test "a viewer cannot add an asset to a watchlist" do
    reset!
    post access_token_path, params: { user_id: users(:viewer).id }

    post watchlist_items_path, params: { asset_id: "polkadot" }

    assert_response :forbidden
    assert_equal 0, MarketFeed::WatchlistItem.count
  end

  test "a viewer sees neither the watchlist link nor the stars" do
    reset!
    post access_token_path, params: { user_id: users(:viewer).id }

    get root_path

    assert_response :success
    assert_select "a", text: "Watchlist", count: 0
    assert_select "button", text: "☆", count: 0
  end

  test "a trader sees the watchlist link and the stars" do
    get root_path

    assert_response :success
    assert_select "a", text: "Watchlist"
    assert_select "button", text: "☆"
  end

  test "a viewer gets the default assets even with watchlist rows stored" do
    MarketFeed::WatchlistItem.create!(user: users(:viewer), asset_id: "dogecoin")
    reset!
    post access_token_path, params: { user_id: users(:viewer).id }

    get root_path

    assert_response :success
    assert_select "p", text: "Bitcoin"
    assert_select "p", text: "Dogecoin", count: 0
  end

  test "an admin reads another user's watchlist" do
    post watchlist_items_path, params: { asset_id: "polkadot" }
    reset!
    post access_token_path, params: { user_id: users(:admin).id }

    get watchlist_items_path(user_id: @trader.id)

    assert_response :success
    assert_select "td", text: "Polkadot"
    assert_select "#watchlist-owner"
  end

  test "an admin removes an asset from another user's watchlist" do
    post watchlist_items_path, params: { asset_id: "polkadot" }
    reset!
    post access_token_path, params: { user_id: users(:admin).id }

    delete watchlist_item_path("polkadot", user_id: @trader.id)

    assert_equal 0, MarketFeed::WatchlistItem.where(user: @trader).count
  end

  test "a trader cannot reach another user's watchlist" do
    get watchlist_items_path(user_id: users(:admin).id)

    assert_response :forbidden
  end

  test "a trader sees no owner selector" do
    get watchlist_items_path

    assert_response :success
    assert_select "#watchlist-owner", count: 0
  end

  test "the watch button opens the market feed with the watched assets" do
    post watchlist_items_path, params: { asset_id: "solana" }

    get watchlist_items_path

    assert_select "#watch-watchlist[href=?]", root_path(asset_ids: [ "solana" ])
  end

  test "an admin watches another user's assets" do
    post watchlist_items_path, params: { asset_id: "solana" }
    reset!
    post access_token_path, params: { user_id: users(:admin).id }

    get watchlist_items_path(user_id: @trader.id)

    assert_select "#watch-watchlist[href=?]", root_path(asset_ids: [ "solana" ])
  end

  test "an empty watchlist offers no watch button" do
    get watchlist_items_path

    assert_select "#watch-watchlist", count: 0
  end
end
