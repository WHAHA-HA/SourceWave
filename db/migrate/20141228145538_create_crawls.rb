class CreateCrawls < ActiveRecord::Migration
  def change
    create_table :crawls do |t|
      t.string :name

      t.timestamps
    end
  end
end
