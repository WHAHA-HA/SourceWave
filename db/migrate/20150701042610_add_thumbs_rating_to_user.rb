class AddThumbsRatingToUser < ActiveRecord::Migration
  def change
    add_column :users, :thumbs_up_count, :integer
    add_column :users, :thumbs_down_count, :integer
  end
end
