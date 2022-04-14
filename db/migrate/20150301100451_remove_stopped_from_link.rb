class RemoveStoppedFromLink < ActiveRecord::Migration
  def change
    remove_column :links, :stopped, :boolean
  end
end
