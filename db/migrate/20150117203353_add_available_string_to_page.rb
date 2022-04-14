class AddAvailableStringToPage < ActiveRecord::Migration
  def change
    add_column :pages, :available, :string
  end
end
