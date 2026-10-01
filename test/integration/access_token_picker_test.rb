require "test_helper"

class AccessTokenPickerTest < ActionDispatch::IntegrationTest
  test "picking a user sets the cookie and the page then shows that user's email and role" do
    selected_user = users(:trader)

    post access_token_path, params: { user_id: selected_user.id }

    assert_redirected_to root_path
    assert cookies[:access_token].present?

    get root_path

    assert_response :success
    assert_select "#current-user-email", text: selected_user.email
    assert_select "#current-user-role", text: selected_user.role
  end

  test "no cookie sends the visitor to the sign in page, where the picker lives" do
    get root_path

    assert_redirected_to sign_in_path

    get sign_in_path

    assert_response :success
    assert_select "#current-user-email", count: 0
    assert_select "#current-user-role", count: 0
    assert_select "select[name=?]", "user_id"
  end

  test "a tampered token is rejected and no user is shown" do
    selected_user = users(:trader)
    valid_token = Authorization::AccessToken.encode(selected_user).token
    tampered_token = valid_token.chop << (valid_token[-1] == "a" ? "b" : "a")

    cookies[:access_token] = tampered_token
    get root_path

    assert_redirected_to sign_in_path
  end

  test "an expired token is rejected and no user is shown" do
    selected_user = users(:trader)
    expired_token = travel_to(2.hours.ago) { Authorization::AccessToken.encode(selected_user).token }

    cookies[:access_token] = expired_token
    get root_path

    assert_redirected_to sign_in_path
  end
end
