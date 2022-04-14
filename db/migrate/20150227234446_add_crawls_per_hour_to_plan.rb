class AddCrawlsPerHourToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :crawls_per_hour, :integer
  end
end
