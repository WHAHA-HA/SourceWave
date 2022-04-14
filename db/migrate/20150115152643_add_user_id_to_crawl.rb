class AddUserIdToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :user_id, :integer
  end
end
