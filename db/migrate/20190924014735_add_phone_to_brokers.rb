class AddPhoneToBrokers < ActiveRecord::Migration[5.2]
  def change
    add_column :brokers, :phone, :string
    add_column :brokers, :phone2, :string
  end
end
