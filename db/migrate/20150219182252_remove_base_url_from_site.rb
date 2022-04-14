class RemoveBaseUrlFromSite < ActiveRecord::Migration
  def change
    remove_column :sites, :base_url, :string
  end
end
