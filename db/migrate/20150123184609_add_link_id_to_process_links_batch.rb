class AddLinkIdToProcessLinksBatch < ActiveRecord::Migration
  def change
    add_column :process_links_batches, :link_id, :integer
  end
end
