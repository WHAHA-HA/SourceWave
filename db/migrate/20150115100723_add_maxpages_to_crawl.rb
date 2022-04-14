class AddMaxpagesToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :maxpages, :integer
  end
end
