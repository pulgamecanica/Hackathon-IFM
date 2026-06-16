# Raw feedback from any ingestion channel.
# Products are linked via raw_feedback_products join table (Decision #3).
# Audio files are managed via Active Storage — no media_attachments table (Decision #6).
# checksum prevents duplicate ingestion of the same payload — enforce before create.
# synthetic denormalized from source.source_type — intentional debt.
#
# feedback_content_type: 0=text, 1=audio, 2=image, 3=video, 4=structured
# channel: 0=web, 1=mobile, 2=email, 3=sms, 4=pos, 5=api, 6=synthetic_channel
# processing_status: 0=pending, 1=processing, 2=processed, 3=failed
#
# Column is named feedback_content_type (not content_type) to avoid collision
# with Active Storage's internal content_type method on blob objects.
class RawFeedback < ApplicationRecord
  # Active Storage — audio attachment is NOT queryable via SQL.
  has_one_attached :audio

  belongs_to :source
  belongs_to :user, optional: true
  belongs_to :location, optional: true
  belongs_to :purchase_data, class_name: "PurchaseDatum", optional: true

  has_many :raw_feedback_products, dependent: :destroy
  has_many :products, through: :raw_feedback_products
  has_one :ai_insight, dependent: :destroy

  # feedback_content_type: 0=text, 1=audio, 2=image, 3=video, 4=structured
  enum :feedback_content_type, { text: 0, audio: 1, image: 2, video: 3, structured: 4 }, validate: true

  # channel: 0=web, 1=mobile, 2=email, 3=sms, 4=pos, 5=api, 6=synthetic_channel
  enum :channel, { web: 0, mobile: 1, email: 2, sms: 3, pos: 4, api: 5, synthetic_channel: 6 }, validate: true

  # processing_status: 0=pending, 1=processing, 2=processed, 3=failed
  enum :processing_status, { pending: 0, processing: 1, processed: 2, failed: 3 }, validate: true

  validates :source, presence: true
  validates :checksum, presence: true, uniqueness: true
  validates :feedback_content_type, presence: true
  validates :channel, presence: true
  validates :processing_status, presence: true

  scope :synthetic, -> { where(synthetic: true) }
  scope :real, -> { where(synthetic: false) }
  scope :pending_processing, -> { where(processing_status: :pending) }
  scope :failed, -> { where(processing_status: :failed) }
  scope :by_channel, ->(ch) { where(channel: ch) }
  scope :recent, -> { order(submitted_at: :desc) }
end
