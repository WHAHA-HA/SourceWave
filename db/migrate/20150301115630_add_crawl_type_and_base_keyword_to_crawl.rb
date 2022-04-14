class AddCrawlTypeAndBaseKeywordToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :crawl_type, :string
    add_column :crawls, :base_keyword, :string
  end
end
