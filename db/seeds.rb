# Seeds for the Product Feedback Intelligence Platform.
# All seeds use find_or_create_by! so they are idempotent.
#
# Seed order (respects FK dependencies):
#   1. Sources         — must exist before RawFeedbacks and PurchaseData
#   2. Locations       — must exist before RawFeedbacks and PurchaseData
#   3. Vendors         — must exist before Products
#   4. Categories      — must exist before Products (roots first, then children)
#   5. Products        — must exist before RawFeedbackProducts, PurchaseData, Ratings
#   6. Users           — must exist before LoyaltyAccounts, PurchaseData, RawFeedbacks
#   7. LoyaltyAccounts — depends on Users
#   8. PurchaseData    — depends on Users, Products, Locations, Sources
#   9. RawFeedbacks    — depends on Sources, Users, Locations, PurchaseData
#  10. RawFeedbackProducts — depends on RawFeedbacks, Products
#  11. AiInsights      — depends on RawFeedbacks
#  12. Ratings         — depends on Products, AiInsights
#
# NOTE: The background stub service POSTs synthetic feedback to the same
# ingestion endpoint as real data. Ensure at least one Source with
# source_type: :synthetic and adapter_key: "stub_service" exists so the
# stub can resolve it without seeding its own records.

puts "Seeding sources..."
synthetic_source = Source.find_or_create_by!(adapter_key: "stub_service") do |s|
  s.name = "Stub Feedback Service"
  s.source_type = :synthetic
  s.config = { "endpoint" => "/api/v1/feedbacks/ingest", "rate_per_minute" => 10 }
  s.active = true
end

web_source = Source.find_or_create_by!(adapter_key: "web_form") do |s|
  s.name = "Web Feedback Form"
  s.source_type = :real
  s.config = {}
  s.active = true
end

puts "Seeding locations..."
# Real coordinates so feedback can be plotted on a live map.
[
  { name: "HQ Store",        city: "New York",   country_code: "US", lat: 40.7128,  long: -74.0060, type: :store },
  { name: "London Flagship", city: "London",     country_code: "GB", lat: 51.5074,  long: -0.1278,  type: :store },
  { name: "Paris Boutique",  city: "Paris",      country_code: "FR", lat: 48.8566,  long: 2.3522,   type: :store },
  { name: "Berlin Outlet",   city: "Berlin",     country_code: "DE", lat: 52.5200,  long: 13.4050,  type: :store },
  { name: "Tokyo Pop-up",    city: "Tokyo",      country_code: "JP", lat: 35.6762,  long: 139.6503, type: :popup },
  { name: "SF Kiosk",        city: "San Francisco", country_code: "US", lat: 37.7749, long: -122.4194, type: :kiosk },
  { name: "EU Warehouse",    city: "Rotterdam",  country_code: "NL", lat: 51.9244,  long: 4.4777,   type: :warehouse }
].each do |attrs|
  location = Location.find_or_initialize_by(name: attrs[:name])
  location.update!(
    city: attrs[:city],
    country_code: attrs[:country_code],
    lat: attrs[:lat],
    long: attrs[:long],
    location_type: attrs[:type]
  )
end

puts "Seeding vendors..."
vendor = Vendor.find_or_create_by!(slug: "acme-corp") do |v|
  v.name = "Acme Corp"
  v.contact_email = "contact@acme.example.com"
end

puts "Seeding categories..."
electronics = Category.find_or_create_by!(slug: "electronics") do |c|
  c.name = "Electronics"
  c.position = 0
end

puts "Seeding products..."
[
  { sku: "ACME-001", name: "Widget Pro",     slug: "widget-pro",     price_cents: 4999 },
  { sku: "ACME-002", name: "Gadget Max",     slug: "gadget-max",     price_cents: 8999 },
  { sku: "ACME-003", name: "Smart Hub Mini", slug: "smart-hub-mini", price_cents: 12999 },
  { sku: "ACME-004", name: "Wireless Buds",  slug: "wireless-buds",  price_cents: 7999 },
  { sku: "ACME-005", name: "Power Bank 20K", slug: "power-bank-20k", price_cents: 3499 }
].each do |attrs|
  Product.find_or_create_by!(sku: attrs[:sku]) do |p|
    p.vendor = vendor
    p.category = electronics
    p.name = attrs[:name]
    p.slug = attrs[:slug]
    p.price_cents = attrs[:price_cents]
    p.currency = "USD"
    p.status = :active
  end
end

puts "Seeding users..."
User.find_or_create_by!(email: "dev@internal.example.com") do |u|
  u.name = "Internal Developer"
  u.user_type = :staff
end

puts "Seeds complete."
