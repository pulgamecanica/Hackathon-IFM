# Ratings are ALWAYS AI-derived (Decision #2). ai_insight_id is NOT NULL.
# One AiInsight produces one Rating PER product referenced in the feedback.
# So for a feedback touching N products, N ratings are created from the single insight.
# product_id + ai_insight_id + dimension uniqueness enforced: one score per dimension
# per (insight, product) pair.
# dimension: 0=overall, 1=quality, 2=value, 3=service, 4=delivery
# score: typically 1.0–5.0, stored as decimal for precision.
# synthetic denormalized from ai_insight -> raw_feedback -> source — intentional debt.
class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.references :ai_insight, null: false, foreign_key: true, index: true
      t.decimal :score, precision: 4, scale: 2, null: false
      # dimension: 0=overall, 1=quality, 2=value, 3=service, 4=delivery
      t.integer :dimension, null: false, default: 0
      # Denormalized from ai_insight -> raw_feedback -> source.source_type.
      t.boolean :synthetic, null: false, default: false
      t.datetime :rated_at, null: false

      t.timestamps
    end

    # One score per dimension per (ai_insight, product) pair.
    add_index :ratings, [ :ai_insight_id, :product_id, :dimension ],
              unique: true, name: "idx_ratings_insight_product_dimension"
    add_index :ratings, [ :product_id, :dimension ]
    add_index :ratings, :synthetic
    add_index :ratings, :rated_at
    add_index :ratings, :score
  end
end
