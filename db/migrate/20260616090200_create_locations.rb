# Physical or virtual locations where products are sold or feedback is attributed.
# location_type: 0=store, 1=warehouse, 2=online, 3=kiosk, 4=popup
class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      # location_type: 0=store, 1=warehouse, 2=online, 3=kiosk, 4=popup
      t.integer :location_type, null: false, default: 0
      t.string :address
      t.string :city
      t.string :country_code, limit: 2
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :long, precision: 10, scale: 7
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :locations, :country_code
    add_index :locations, :location_type
  end
end
