class AddCrawlId2ToPage < ActiveRecord::Migration
  def change
    add_column :pages, :crawl_id, :integer
  end
end
