class AddDoToCrawls < ActiveRecord::Migration
  def change
    add_column :crawls, :is_do, :boolean
  end
end
