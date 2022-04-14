class AddSiteMetricsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :da, :float
    add_column :sites, :pa, :float
    add_column :sites, :tf, :float
    add_column :sites, :cf, :float
  end
end
