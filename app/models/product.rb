# Product images are managed via Active Storage — no media_attachments table (Decision #6).
# status: 0=draft, 1=active, 2=discontinued, 3=archived
class Product < ApplicationRecord
  # Active Storage — images are NOT queryable via SQL, stored via configured service.
  has_many_attached :images

  belongs_to :vendor
  belongs_to :category, optional: true

  has_many :external_identifiers, as: :identifiable, dependent: :destroy
  has_many :raw_feedback_products, dependent: :destroy
  has_many :raw_feedbacks, through: :raw_feedback_products
  has_many :purchase_data, class_name: "PurchaseDatum", dependent: :restrict_with_error
  has_many :ratings, dependent: :destroy

  # status: 0=draft, 1=active, 2=discontinued, 3=archived
  enum :status, { draft: 0, active: 1, discontinued: 2, archived: 3 }, validate: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, presence: true, length: { is: 3 }
  validates :status, presence: true

  scope :active, -> { where(status: :active) }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
  end
end
