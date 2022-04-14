class AddDomainMetricsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :tf, :string
    add_column :sites, :cf, :string
    add_column :sites, :da, :string
    add_column :sites, :pa, :string
  end
end
