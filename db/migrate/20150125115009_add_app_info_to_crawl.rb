class AddAppInfoToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :app_url, :text
    add_column :crawls, :app_name, :string
  end
end
