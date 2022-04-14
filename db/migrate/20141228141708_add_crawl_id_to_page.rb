class AddCrawlIdToPage < ActiveRecord::Migration
  def change
    add_column :pages, :crawl_id, :string
  end
end
