require 'test_helper'

class PendingCrawlsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
