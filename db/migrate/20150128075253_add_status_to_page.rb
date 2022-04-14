class AddStatusToPage < ActiveRecord::Migration
  def change
    add_column :pages, :status, :string
  end
end
