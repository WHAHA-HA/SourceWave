class AddHerokuAppIdToSidekiqStat < ActiveRecord::Migration
  def change
    add_column :sidekiq_stats, :heroku_app_id, :integer
  end
end
