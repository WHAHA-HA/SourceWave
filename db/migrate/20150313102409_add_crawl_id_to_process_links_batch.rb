class AddCrawlIdToProcessLinksBatch < ActiveRecord::Migration
  def change
    add_column :process_links_batches, :crawl_id, :integer
  end
end
