class CreateBrokers < ActiveRecord::Migration[5.2]
  def change
    create_table :brokers do |t|
      t.string :name
      t.string :email
      t.string :creci
      t.string :state
      t.string :situation
      t.references :page_control, foreign_key: true

      t.timestamps
    end
  end
end
