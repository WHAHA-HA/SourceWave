class AddDbUrlToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :db_url, :string
  end
end
