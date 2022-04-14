class AddAvailableToPage < ActiveRecord::Migration
  def change
    add_column :pages, :available, :boolean
  end
end
