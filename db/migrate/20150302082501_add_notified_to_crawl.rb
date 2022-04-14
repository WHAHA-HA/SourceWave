class AddNotifiedToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :notified, :boolean
  end
end
