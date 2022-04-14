class AddTotalMinutesToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :total_minutes, :integer
  end
end
