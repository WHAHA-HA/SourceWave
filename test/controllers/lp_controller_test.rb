require 'test_helper'

class LpControllerTest < ActionController::TestCase
  test "should get marketplace" do
    get :marketplace
    assert_response :success
  end

end
