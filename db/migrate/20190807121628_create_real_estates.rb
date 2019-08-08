class CreateRealEstates < ActiveRecord::Migration[5.2]
  def change
    create_table :real_estates do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :address
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :creci
      t.string :situation
      t.string :technical_manager_name
      t.string :technical_manager_creci
      t.references :page_control, foreign_key: true

      t.timestamps
    end
  end
end
