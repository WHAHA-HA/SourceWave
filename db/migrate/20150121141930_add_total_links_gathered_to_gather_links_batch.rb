class AddTotalLinksGatheredToGatherLinksBatch < ActiveRecord::Migration
  def change
    add_column :gather_links_batches, :total_links_gathered, :string
  end
end
