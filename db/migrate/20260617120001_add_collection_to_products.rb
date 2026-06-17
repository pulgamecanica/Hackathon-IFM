class AddCollectionToProducts < ActiveRecord::Migration[8.1]
  def change
    # Seasonal collection (e.g. "SS27", "AW26"); distinct from category, which is
    # the garment function (coats, dresses, bags…).
    add_column :products, :collection, :string
    add_index :products, :collection
  end
end
