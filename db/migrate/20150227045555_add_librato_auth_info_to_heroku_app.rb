class AddLibratoAuthInfoToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :librato_user, :string
    add_column :heroku_apps, :librato_token, :string
  end
end
