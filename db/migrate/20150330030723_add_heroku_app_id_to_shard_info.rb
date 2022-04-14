class AddHerokuAppIdToShardInfo < ActiveRecord::Migration
  def change
    add_column :shard_infos, :heroku_app_id, :integer
  end
end
