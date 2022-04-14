class AddPositionToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :pos, :integer
  end
end
