class AddProcessedToSidekiqStat < ActiveRecord::Migration
  def change
    add_column :sidekiq_stats, :processed, :integer
  end
end
