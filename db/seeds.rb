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
# Upsert so reseeding refreshes the name even if the row already exists.
vendor = Vendor.find_or_initialize_by(slug: "luma")
vendor.update!(name: "LUMA", contact_email: "atelier@luma.example.com")

puts "Seeding categories..."
apparel = Category.find_or_initialize_by(slug: "apparel")
apparel.update!(name: "Apparel", position: 0)
accessories = Category.find_or_initialize_by(slug: "accessories")
accessories.update!(name: "Accessories", position: 1)

puts "Seeding products..."
[
  { sku: "ML-COAT-01",  name: "Cashmere Wrap Coat",      slug: "cashmere-wrap-coat",      price_cents: 189000, cat: apparel },
  { sku: "ML-DRESS-01", name: "Silk Slip Dress",         slug: "silk-slip-dress",         price_cents: 98000,  cat: apparel },
  { sku: "ML-BLAZER-01", name: "Tailored Wool Blazer",   slug: "tailored-wool-blazer",    price_cents: 145000, cat: apparel },
  { sku: "ML-BOOT-01",  name: "Leather Ankle Boots",     slug: "leather-ankle-boots",     price_cents: 76000,  cat: accessories },
  { sku: "ML-BAG-01",   name: "Quilted Leather Handbag", slug: "quilted-leather-handbag", price_cents: 132000, cat: accessories },
  { sku: "ML-SCARF-01", name: "Hand-Rolled Silk Scarf",  slug: "hand-rolled-silk-scarf",  price_cents: 32000,  cat: accessories }
].each do |attrs|
  product = Product.find_or_initialize_by(sku: attrs[:sku])
  product.update!(
    vendor: vendor,
    category: attrs[:cat],
    name: attrs[:name],
    slug: attrs[:slug],
    price_cents: attrs[:price_cents],
    currency: "EUR",
    status: :active
  )
end

puts "Seeding users..."
User.find_or_create_by!(email: "dev@internal.example.com") do |u|
  u.name = "Internal Developer"
  u.user_type = :staff
end

puts "Seeds complete."
