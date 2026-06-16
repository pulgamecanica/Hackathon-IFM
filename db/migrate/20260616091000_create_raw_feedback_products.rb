# Join table: one RawFeedback can reference many Products (Decision #3).
# This replaces the old single product_id column on raw_feedbacks.
# position allows ordered product references within a single feedback item.
class CreateRawFeedbackProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :raw_feedback_products do |t|
      t.references :raw_feedback, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :raw_feedback_products, [ :raw_feedback_id, :product_id ], unique: true, name: "idx_raw_feedback_products_unique"
    add_index :raw_feedback_products, [ :raw_feedback_id, :position ]
  end
end
