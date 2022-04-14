class CreateHerokuApps < ActiveRecord::Migration
  def change
    create_table :heroku_apps do |t|
      t.string :name
      t.text :url
      t.integer :crawl_id
      t.string :status

      t.timestamps null: false
    end
  end
end
