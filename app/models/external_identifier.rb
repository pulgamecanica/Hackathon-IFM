# Polymorphic external identifiers: UPC, EAN, loyalty IDs, vendor codes, etc.
# The (scheme, value) pair is globally unique across all identifiable types.
class ExternalIdentifier < ApplicationRecord
  belongs_to :identifiable, polymorphic: true

  validates :scheme, presence: true
  validates :value, presence: true, uniqueness: { scope: :scheme }
  validates :expires_at, comparison: { greater_than: Time.current }, allow_nil: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_scheme, ->(scheme) { where(scheme: scheme) }
end
