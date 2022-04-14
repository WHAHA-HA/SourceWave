class RemoveAvailableSitesFromCrawl < ActiveRecord::Migration
  def change
    remove_column :crawls, :available_sites, :text
  end
end
