class AddProcessorNameToLink < ActiveRecord::Migration
  def change
    add_column :links, :processor_name, :string
  end
end
