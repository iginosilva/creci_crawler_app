class CreatePageControls < ActiveRecord::Migration[5.2]
  def change
    create_table :page_controls do |t|
      t.string :letter
      t.string :page
      t.integer :status

      t.timestamps
    end
  end
end
