class AddStatusToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :status, :string
  end
end
