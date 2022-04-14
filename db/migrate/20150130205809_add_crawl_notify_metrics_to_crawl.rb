class AddCrawlNotifyMetricsToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :moz_da, :integer
    add_column :crawls, :majestic_tf, :integer
    add_column :crawls, :notify_me_after, :integer
  end
end
