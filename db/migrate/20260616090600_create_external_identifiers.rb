# Polymorphic identifiers: barcodes, ISBNs, UPC, vendor codes, loyalty IDs, etc.
# The (scheme, value) pair is globally unique — the same barcode cannot exist twice.
# identifiable_type examples: "Product", "User", "Vendor"
class CreateExternalIdentifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :external_identifiers do |t|
      t.references :identifiable, polymorphic: true, null: false, index: true
      t.string :scheme, null: false       # e.g. "upc", "ean13", "loyalty_id"
      t.string :value, null: false
      t.string :issued_by
      t.datetime :expires_at

      t.timestamps
    end

    add_index :external_identifiers, [ :scheme, :value ], unique: true
    add_index :external_identifiers, :scheme
  end
end
