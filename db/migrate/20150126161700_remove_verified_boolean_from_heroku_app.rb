class RemoveVerifiedBooleanFromHerokuApp < ActiveRecord::Migration
  def change
    remove_column :heroku_apps, :verified, :boolean
  end
end
