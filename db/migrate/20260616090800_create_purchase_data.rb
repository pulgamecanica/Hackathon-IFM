# Purchase records link a user to a product at a location via a source.
# synthetic flag is denormalized from sources.source_type for fast dashboard queries.
# Intentional denormalization debt: synthetic must be kept in sync with the source record.
class CreatePurchaseData < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_data do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :location, foreign_key: true, index: true
      t.references :source, foreign_key: true, index: true
      t.string :external_transaction_id
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents
      t.string :currency, limit: 3, null: false, default: "USD"
      t.datetime :purchased_at, null: false
      # Denormalized from sources.source_type — intentional for dashboard filtering.
      t.boolean :synthetic, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :purchase_data, :external_transaction_id
    add_index :purchase_data, :purchased_at
    add_index :purchase_data, :synthetic
    add_index :purchase_data, [ :user_id, :purchased_at ]
    add_index :purchase_data, [ :product_id, :purchased_at ]
  end
end
