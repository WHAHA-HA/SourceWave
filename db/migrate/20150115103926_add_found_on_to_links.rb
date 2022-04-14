class AddFoundOnToLinks < ActiveRecord::Migration
  def change
    add_column :links, :found_on, :text
  end
end
