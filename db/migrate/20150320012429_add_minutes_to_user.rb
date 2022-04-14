class AddMinutesToUser < ActiveRecord::Migration
  def change
    add_column :users, :minutes_used, :integer
    add_column :users, :minutes_available, :integer
  end
end
