class AddYearsStatsToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :crawl_start_date, :datetime
    add_column :crawls, :crawl_end_date, :datetime
  end
end
