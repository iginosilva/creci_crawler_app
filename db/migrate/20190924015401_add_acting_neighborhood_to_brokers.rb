class AddActingNeighborhoodToBrokers < ActiveRecord::Migration[5.2]
  def change
    add_column :brokers, :acting_neighborhood, :string
  end
end
