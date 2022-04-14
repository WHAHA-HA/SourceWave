class AddDoneCrawlersToUserDashboard < ActiveRecord::Migration
  def change
    add_column :user_dashboards, :done_crawlers, :integer
  end
end
