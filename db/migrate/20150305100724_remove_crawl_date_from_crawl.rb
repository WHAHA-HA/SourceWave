class RemoveCrawlDateFromCrawl < ActiveRecord::Migration
  def change
    remove_column :crawls, :crawl_start_date, :datetime
    remove_column :crawls, :crawl_end_date, :datetime
  end
end
