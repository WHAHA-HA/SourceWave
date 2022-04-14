class CreateVerifyMajesticBatches < ActiveRecord::Migration
  def change
    create_table :verify_majestic_batches do |t|
      t.integer :site_id
      t.datetime :started_at
      t.datetime :finished_at
      t.string :batch_id

      t.timestamps null: false
    end
  end
end
