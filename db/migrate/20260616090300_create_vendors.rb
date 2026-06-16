class CreateVendors < ActiveRecord::Migration[8.1]
  def change
    create_table :vendors do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :contact_email
      t.string :website
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :vendors, :slug, unique: true
  end
end
