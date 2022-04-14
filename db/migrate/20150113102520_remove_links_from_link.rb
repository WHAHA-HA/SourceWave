class RemoveLinksFromLink < ActiveRecord::Migration
  def change
    remove_column :links, :links, :text
  end
end
