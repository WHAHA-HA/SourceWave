class AddPageStringMetricsToPage < ActiveRecord::Migration
  def change
    add_column :pages, :citationflow, :float
    add_column :pages, :trustflow, :float
    add_column :pages, :trustmetric, :float
    add_column :pages, :pa, :float
    add_column :pages, :da, :float
  end
end
