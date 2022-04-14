class AddDbUrlToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :db_url, :string
  end
end
