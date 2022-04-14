class RemoveMinutesFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :minutes_used, :integer
    remove_column :users, :minutes_available, :integer
  end
end
