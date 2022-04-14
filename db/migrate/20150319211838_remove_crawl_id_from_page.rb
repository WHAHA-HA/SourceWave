class RemoveCrawlIdFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :crawl_id, :string
  end
end
