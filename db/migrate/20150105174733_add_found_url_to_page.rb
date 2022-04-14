class AddFoundUrlToPage < ActiveRecord::Migration
  def change
    add_column :pages, :found_on, :text
  end
end
