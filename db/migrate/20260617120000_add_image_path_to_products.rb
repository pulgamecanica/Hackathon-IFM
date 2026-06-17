# Static image link for each product (served from /public/products). Active
# Storage `images` remains available for uploaded media; this is the simple
# catalog thumbnail used across the dashboard.
class AddImagePathToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_path, :string
  end
end
