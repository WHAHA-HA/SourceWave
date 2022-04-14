class AddCrawlsPerDayToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :crawls_per_day, :integer
  end
end
