class AddSoldToPage < ActiveRecord::Migration
  def change
    add_column :pages, :sold, :boolean
  end
end
