class AddLastCrawlToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_crawl, :datetime
  end
end
