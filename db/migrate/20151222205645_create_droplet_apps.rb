class CreateDropletApps < ActiveRecord::Migration
  def change
    create_table :droplet_apps do |t|
      t.string :name
      t.text :url
      t.integer :crawl_id
      t.string :status
      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :finished_at
      t.string :batch_id
      t.string :verified
      t.integer :pos
      t.integer :position
      t.boolean :shutdown
      t.string :librator_user
      t.string :librato_token
      t.hstore :formation
      t.string :db_url
      t.string :db_user
      t.string :db_pass
      t.string :db_host
      t.string :db_port
      t.string :db_name
      t.integer :user_id
      t.string :droplet_name

      t.timestamps null: false
    end
  end
end
