class AddMaxAllowedToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :max_pages_allowed, :integer
  end
end
