class AddHeadersToPage < ActiveRecord::Migration
  def change
    add_column :pages, :headers, :text
  end
end
