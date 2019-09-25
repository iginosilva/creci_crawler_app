class AddEmail2ToBrokers < ActiveRecord::Migration[5.2]
  def change
    add_column :brokers, :email2, :string
  end
end
