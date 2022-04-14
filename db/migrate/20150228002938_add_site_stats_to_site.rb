class AddSiteStatsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :total_urls_found, :integer
    add_column :sites, :total_pages_crawled, :integer
    add_column :sites, :total_expired, :integer
    add_column :sites, :total_broken, :integer
    add_column :sites, :total_internal, :integer
    add_column :sites, :total_external, :integer
    add_column :sites, :gather_status, :string
    add_column :sites, :processing_status, :string
  end
end
