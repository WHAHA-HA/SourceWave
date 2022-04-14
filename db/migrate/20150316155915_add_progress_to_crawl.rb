class AddProgressToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :progress, :float
  end
end
