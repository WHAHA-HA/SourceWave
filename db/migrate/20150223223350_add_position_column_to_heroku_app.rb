class AddPositionColumnToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :position, :integer
  end
end
