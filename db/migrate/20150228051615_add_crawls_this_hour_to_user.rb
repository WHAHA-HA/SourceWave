class AddCrawlsThisHourToUser < ActiveRecord::Migration
  def change
    add_column :users, :crawls_this_hour, :integer
    add_column :users, :first_crawl, :datetime
  end
end
