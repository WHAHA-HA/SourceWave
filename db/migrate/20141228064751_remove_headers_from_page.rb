class RemoveHeadersFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :headers, :string
  end
end
