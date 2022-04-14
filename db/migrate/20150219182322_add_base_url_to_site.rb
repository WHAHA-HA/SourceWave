class AddBaseUrlToSite < ActiveRecord::Migration
  def change
    add_column :sites, :base_url, :text
  end
end
