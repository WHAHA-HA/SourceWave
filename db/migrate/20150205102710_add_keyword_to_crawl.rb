class AddKeywordToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :keyword, :string
  end
end
