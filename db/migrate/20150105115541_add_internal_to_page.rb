class AddInternalToPage < ActiveRecord::Migration
  def change
    add_column :pages, :internal, :boolean
  end
end
