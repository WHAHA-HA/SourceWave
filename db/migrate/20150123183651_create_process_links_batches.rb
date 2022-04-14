class CreateProcessLinksBatches < ActiveRecord::Migration
  def change
    create_table :process_links_batches do |t|
      t.integer :site_id
      t.string :status
      t.datetime :started_at
      t.datetime :finished_at
      t.string :batch_id
      t.string :pages_per_second
      t.string :est_crawl_time

      t.timestamps null: false
    end
  end
end
