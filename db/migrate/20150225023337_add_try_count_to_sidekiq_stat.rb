class AddTryCountToSidekiqStat < ActiveRecord::Migration
  def change
    add_column :sidekiq_stats, :try_count, :integer
  end
end
