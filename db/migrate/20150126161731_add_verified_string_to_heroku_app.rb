class AddVerifiedStringToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :verified, :string
  end
end
