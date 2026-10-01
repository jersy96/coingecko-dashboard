require "test_helper"

class ActivityLogTest < ActionDispatch::IntegrationTest
  test "a watchlist change shows up in the log for an admin" do
    post access_token_path, params: { user_id: users(:trader).id }
    post watchlist_items_path, params: { asset_id: "polkadot" }

    reset!
    post access_token_path, params: { user_id: users(:admin).id }
    get activity_entries_path

    assert_response :success
    assert_select "p", text: "trader@example.com"
    assert_select "td", text: "Watchlist item added"
    assert_select "td", text: "Polkadot"
  end

  test "a trader cannot read the activity log" do
    post access_token_path, params: { user_id: users(:trader).id }

    get activity_entries_path

    assert_response :forbidden
  end

  test "a trader sees no activity log link" do
    post access_token_path, params: { user_id: users(:trader).id }

    get root_path

    assert_response :success
    assert_select "a", text: "Activity log", count: 0
  end

  test "an admin acting on another watchlist is recorded as the actor" do
    post access_token_path, params: { user_id: users(:admin).id }
    post watchlist_items_path, params: { asset_id: "solana", user_id: users(:trader).id }

    get activity_entries_path

    assert_response :success
    assert_select "p", text: "admin@example.com"
  end

  test "the log paginates" do
    post access_token_path, params: { user_id: users(:admin).id }
    60.times { |index| post watchlist_items_path, params: { asset_id: "asset-#{index}" } }

    get activity_entries_path(page: 2)

    assert_response :success
    assert_select "a", text: "Previous"
  end
end
