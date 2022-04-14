class AddRedisUrlToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :redis_url, :string
  end
end
