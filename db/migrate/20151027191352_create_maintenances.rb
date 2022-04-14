class CreateMaintenances < ActiveRecord::Migration
  def change
    create_table :maintenances do |t|
      t.boolean :enabled, default: false
      t.text :message

      t.timestamps null: false
    end
  end
end
