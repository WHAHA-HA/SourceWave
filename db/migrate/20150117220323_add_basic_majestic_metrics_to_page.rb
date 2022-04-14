class AddBasicMajesticMetricsToPage < ActiveRecord::Migration
  def change
    add_column :pages, :citationflow, :string
    add_column :pages, :trustflow, :string
    add_column :pages, :trustmetric, :string
  end
end
