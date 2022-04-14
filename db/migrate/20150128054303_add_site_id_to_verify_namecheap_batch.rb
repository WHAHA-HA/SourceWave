class AddSiteIdToVerifyNamecheapBatch < ActiveRecord::Migration
  def change
    add_column :verify_namecheap_batches, :site_id, :integer
  end
end
