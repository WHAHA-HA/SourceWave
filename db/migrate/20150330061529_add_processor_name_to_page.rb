class AddProcessorNameToPage < ActiveRecord::Migration
  def change
    add_column :pages, :processor_name, :string
  end
end
