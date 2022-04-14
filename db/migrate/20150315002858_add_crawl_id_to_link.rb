class AddCrawlIdToLink < ActiveRecord::Migration
  def change
    add_column :links, :crawl_id, :integer
  end
end
