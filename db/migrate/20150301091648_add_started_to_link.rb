class AddStartedToLink < ActiveRecord::Migration
  def change
    add_column :links, :started, :boolean
  end
end
