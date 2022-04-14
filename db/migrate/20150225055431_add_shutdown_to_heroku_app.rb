class AddShutdownToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :shutdown, :boolean
  end
end
