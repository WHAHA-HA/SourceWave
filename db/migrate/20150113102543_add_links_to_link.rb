class AddLinksToLink < ActiveRecord::Migration
  def change
    add_column :links, :links, :text, array: true
  end
end
