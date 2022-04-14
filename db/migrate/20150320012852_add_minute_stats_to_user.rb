class AddMinuteStatsToUser < ActiveRecord::Migration
  def change
    add_column :users, :minutes_used, :float
    add_column :users, :minutes_available, :float
  end
end
