class AddMsgToCrawl < ActiveRecord::Migration
  def change
    add_column :crawls, :msg, :string
  end
end
