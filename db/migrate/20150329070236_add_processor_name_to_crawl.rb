class AddProcessorNameToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :processor_name, :string
  end
end
