class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :url
      t.string :status_code
      t.string :mime_type
      t.string :length
      t.string :redirect_through
      t.string :headers
      t.text :links

      t.timestamps
    end
  end
end
