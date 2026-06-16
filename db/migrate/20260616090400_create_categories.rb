# Self-referential category tree. parent_id NULL = root category.
# position is used for ordering siblings; enforce in application layer.
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :parent, foreign_key: { to_table: :categories }, index: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, [ :parent_id, :position ]
  end
end
