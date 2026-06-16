# Raw feedback from any channel. Product linkage is via raw_feedback_products join table
# (Decision #3: one feedback can span many products).
# checksum prevents duplicate ingestion of the same payload.
# processing_status: 0=pending, 1=processing, 2=processed, 3=failed
# content_type: 0=text, 1=audio, 2=image, 3=video, 4=structured
# channel: 0=web, 1=mobile, 2=email, 3=sms, 4=pos, 5=api, 6=synthetic
# Audio attachments are managed via Active Storage (has_one_attached :audio).
# synthetic denormalized from sources.source_type — intentional debt.
class CreateRawFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :raw_feedbacks do |t|
      t.references :source, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true
      t.references :location, foreign_key: true, index: true
      t.references :purchase_data, foreign_key: true, index: true
      t.text :content
      # feedback_content_type: 0=text, 1=audio, 2=image, 3=video, 4=structured
      # Named feedback_content_type (not content_type) to avoid collision with
      # Active Storage's internal content_type method on blob objects.
      t.integer :feedback_content_type, null: false, default: 0
      # channel: 0=web, 1=mobile, 2=email, 3=sms, 4=pos, 5=api, 6=synthetic
      t.integer :channel, null: false, default: 0
      t.string :language, limit: 10
      t.datetime :submitted_at
      # processing_status: 0=pending, 1=processing, 2=processed, 3=failed
      t.integer :processing_status, null: false, default: 0
      # Denormalized from sources.source_type — intentional for dashboard filtering.
      t.boolean :synthetic, null: false, default: false
      t.string :checksum, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :raw_feedbacks, :checksum, unique: true
    add_index :raw_feedbacks, :processing_status
    add_index :raw_feedbacks, :synthetic
    add_index :raw_feedbacks, :submitted_at
    add_index :raw_feedbacks, :channel
    add_index :raw_feedbacks, [ :source_id, :submitted_at ]
  end
end
