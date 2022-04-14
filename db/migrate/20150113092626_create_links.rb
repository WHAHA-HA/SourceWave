class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.integer :site_id
      t.text :links

      t.timestamps null: false
    end
  end
end
