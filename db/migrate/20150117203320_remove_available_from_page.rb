class RemoveAvailableFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :available, :boolean
  end
end
