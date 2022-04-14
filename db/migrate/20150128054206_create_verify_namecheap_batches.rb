class CreateVerifyNamecheapBatches < ActiveRecord::Migration
  def change
    create_table :verify_namecheap_batches do |t|
      t.integer :page_id
      t.string :batch_id
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps null: false
    end
  end
end
