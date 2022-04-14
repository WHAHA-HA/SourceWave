class RemovePageStringMetricsFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :citationflow, :string
    remove_column :pages, :trustflow, :string
    remove_column :pages, :trustmetric, :string
    remove_column :pages, :pa, :string
    remove_column :pages, :da, :string
  end
end
