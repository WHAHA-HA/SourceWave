class CreateGatherLinksBatches < ActiveRecord::Migration
  def change
    create_table :gather_links_batches do |t|
      t.integer :site_id
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at
      t.string :batch_id

      t.timestamps null: false
    end
  end
end
