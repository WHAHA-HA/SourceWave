class AddCrawlDateToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :crawl_start_date, :string
    add_column :crawls, :crawl_end_date, :string
  end
end
