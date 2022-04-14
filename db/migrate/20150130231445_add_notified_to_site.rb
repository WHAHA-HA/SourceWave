class AddNotifiedToSite < ActiveRecord::Migration
  def change
    add_column :sites, :notified, :boolean
  end
end
