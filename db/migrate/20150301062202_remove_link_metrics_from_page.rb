class RemoveLinkMetricsFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :refdomains, :string
    remove_column :pages, :backlinks, :string
  end
end
