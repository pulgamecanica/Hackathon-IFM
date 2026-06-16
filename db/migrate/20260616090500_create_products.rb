# Products belong to a vendor and optionally a category.
# status: 0=draft, 1=active, 2=discontinued, 3=archived
# price_cents + currency avoids floating-point money errors.
# Images are managed via Active Storage (has_many_attached :images) — no media table.
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :vendor, null: false, foreign_key: true, index: true
      t.references :category, foreign_key: true, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :sku, null: false
      t.text :description
      t.integer :price_cents
      t.string :currency, limit: 3, null: false, default: "USD"
      # status: 0=draft, 1=active, 2=discontinued, 3=archived
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :status
  end
end
