class RemoveSiteMetricsFromSite < ActiveRecord::Migration
  def change
    remove_column :sites, :da, :string
    remove_column :sites, :pa, :string
    remove_column :sites, :tf, :string
    remove_column :sites, :cf, :string
  end
end
