class CreateShardInfos < ActiveRecord::Migration
  def change
    create_table :shard_infos do |t|
      t.integer :crawl_id
      t.string :processor_name
      t.string :db_url
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
