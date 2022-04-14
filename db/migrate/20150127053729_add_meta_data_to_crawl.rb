class AddMetaDataToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :total_urls_found, :integer
    add_column :crawls, :total_pages_crawled, :integer
    add_column :crawls, :total_expired, :integer
    add_column :crawls, :total_broken, :integer
    add_column :crawls, :total_sites, :integer
    add_column :crawls, :total_internal, :integer
    add_column :crawls, :total_external, :integer
  end
end
