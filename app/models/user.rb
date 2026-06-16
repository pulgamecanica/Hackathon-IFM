# Users are internal "collection developers" — no auth columns by design (Decision #1).
# No password_digest, no session tokens. Authentication is explicitly out of scope.
class User < ApplicationRecord
  # user_type: 0=customer, 1=staff, 2=synthetic
  enum :user_type, { customer: 0, staff: 1, synthetic: 2 }, validate: true

  has_one :loyalty_account, dependent: :destroy
  has_many :purchase_data, class_name: "PurchaseDatum", dependent: :nullify
  has_many :raw_feedbacks, dependent: :nullify
  has_many :external_identifiers, as: :identifiable, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :user_type, presence: true
end
