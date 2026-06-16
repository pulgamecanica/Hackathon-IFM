# location_type: 0=store, 1=warehouse, 2=online, 3=kiosk, 4=popup
class Location < ApplicationRecord
  # prefix avoids clash with AR's `store` class method (e.g. `location_type_store?`)
  enum :location_type, { store: 0, warehouse: 1, online: 2, kiosk: 3, popup: 4 }, prefix: true, validate: true

  has_many :purchase_data, class_name: "PurchaseDatum", dependent: :nullify
  has_many :raw_feedbacks, dependent: :nullify

  validates :name, presence: true
  validates :location_type, presence: true
  validates :country_code, length: { is: 2 }, allow_blank: true
end
