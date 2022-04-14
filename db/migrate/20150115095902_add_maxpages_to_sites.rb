class AddMaxpagesToSites < ActiveRecord::Migration
  def change
    add_column :sites, :maxpages, :integer
  end
end
