class AddProcessToLink < ActiveRecord::Migration
  def change
    add_column :links, :process, :boolean
  end
end
