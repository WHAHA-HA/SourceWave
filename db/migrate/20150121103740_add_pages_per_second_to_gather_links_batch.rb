class AddPagesPerSecondToGatherLinksBatch < ActiveRecord::Migration
  def change
    add_column :gather_links_batches, :pages_per_second, :string
    add_column :gather_links_batches, :est_crawl_time, :string
  end
end
