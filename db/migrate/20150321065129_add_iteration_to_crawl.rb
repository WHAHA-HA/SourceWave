class AddIterationToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :iteration, :integer
  end
end
