class AddAvailableSitesArrayToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :available_sites, :text, array:true, default: []
  end
end
