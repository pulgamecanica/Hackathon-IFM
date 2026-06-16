# AI-derived analysis for a single RawFeedback (1:1, Decision #4).
# product_id is intentionally ABSENT here (dropped from prior design).
# Rationale: a RawFeedback spans many products; AiInsight is per-feedback.
# Per-product ratings are created from this insight via the ratings table.
# sentiment: 0=negative, 1=neutral, 2=positive, 3=mixed
# synthetic denormalized from sources.source_type — intentional debt.
class CreateAiInsights < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_insights do |t|
      t.references :raw_feedback, null: false, foreign_key: true, index: { unique: true }
      t.string :model_version, null: false
      # sentiment: 0=negative, 1=neutral, 2=positive, 3=mixed
      t.integer :sentiment
      t.decimal :sentiment_score, precision: 5, scale: 4
      t.text :summary
      t.text :key_themes
      t.string :language_detected, limit: 10
      t.jsonb :topics, null: false, default: {}
      t.decimal :confidence, precision: 5, scale: 4
      # Denormalized from raw_feedback -> source.source_type — intentional debt.
      t.boolean :synthetic, null: false, default: false
      t.datetime :generated_at, null: false

      t.timestamps
    end

    add_index :ai_insights, :sentiment
    add_index :ai_insights, :synthetic
    add_index :ai_insights, :generated_at
  end
end
