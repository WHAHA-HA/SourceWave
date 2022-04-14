class AddStoppedToLink < ActiveRecord::Migration
  def change
    add_column :links, :stopped, :boolean
  end
end
