class AddSimpleUrlToPages < ActiveRecord::Migration
  def change
    add_column :pages, :simple_url, :text
  end
end
