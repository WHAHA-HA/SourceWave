class RemoveUrlFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :url, :string
  end
end
