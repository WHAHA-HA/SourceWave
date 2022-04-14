class AddBaseUrlsToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :base_urls, :text, array:true, default: []
  end
end
