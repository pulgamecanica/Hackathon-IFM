# Self-referential category tree. parent_id NULL = root category.
class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error
  has_many :products, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :not_self_referential

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name) }

  private

  def not_self_referential
    errors.add(:parent_id, "cannot be the category itself") if parent_id == id && id.present?
  end
end
