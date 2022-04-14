class AddVerifiedToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :verified, :boolean
  end
end
