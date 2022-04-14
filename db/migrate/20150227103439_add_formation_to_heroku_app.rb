class AddFormationToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :formation, :hstore
  end
end
