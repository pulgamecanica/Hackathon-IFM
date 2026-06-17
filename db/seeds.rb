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

# In-store seller assistant — the LUMA Concierge PWA where sellers log feedback
# captured from clients at the point of sale.
seller_source = Source.find_or_create_by!(adapter_key: "seller_app") do |s|
  s.name = "Seller Concierge App"
  s.source_type = :real
  s.config = {}
  s.active = true
end

puts "Seeding locations..."
# Real coordinates so feedback can be plotted on a live map.
[
  { name: "Paris Boutique",  city: "Paris",      country_code: "FR", lat: 48.8566,  long: 2.3522,   type: :store },
  { name: "Milan Boutique",    city: "Milan",    country_code: "IT", lat: 45.4642, long: 9.1900,  type: :store },
  { name: "Rome Boutique",     city: "Rome",     country_code: "IT", lat: 41.9028, long: 12.4964, type: :store },
  { name: "Florence Boutique", city: "Florence", country_code: "IT", lat: 43.7696, long: 11.2558, type: :store },
  { name: "Naples Boutique",   city: "Naples",   country_code: "IT", lat: 40.8518, long: 14.2681, type: :store },
  { name: "Venice Boutique",   city: "Venice",   country_code: "IT", lat: 45.4408, long: 12.3155, type: :store }
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
categories = {
  coats:    Category.find_or_initialize_by(slug: "coats-jackets").tap { _1.update!(name: "Coats & Jackets", position: 0) },
  dresses:  Category.find_or_initialize_by(slug: "dresses").tap { _1.update!(name: "Dresses", position: 1) },
  skirts:   Category.find_or_initialize_by(slug: "skirts").tap { _1.update!(name: "Skirts", position: 2) },
  trousers: Category.find_or_initialize_by(slug: "trousers").tap { _1.update!(name: "Trousers", position: 3) },
  bags:     Category.find_or_initialize_by(slug: "bags").tap { _1.update!(name: "Bags", position: 4) },
  shoes:    Category.find_or_initialize_by(slug: "shoes").tap { _1.update!(name: "Shoes", position: 5) }
}

puts "Seeding products..."
# The catalog mirrors the curated images in /public/products (one per garment).
# `cat` is the garment FUNCTION (coats, dresses, bags…); `collection` is the
# seasonal drop the piece belongs to (e.g. SS27, AW26) — two orthogonal facets.
[
  { sku: "LUMA-CO-001", name: "Grey Wool Formal Coat",           slug: "grey-wool-formal-coat",           price_cents: 249000, cat: :coats,    collection: "AW26" },
  { sku: "LUMA-DR-001", name: "Burgundy Knit Maxi Dress",        slug: "burgundy-knit-maxi-dress",        price_cents: 89000,  cat: :dresses,  collection: "AW26" },
  { sku: "LUMA-BG-001", name: "Sage Padlock Handbag",            slug: "sage-padlock-handbag",            price_cents: 159000, cat: :bags,     collection: "SS27" },
  { sku: "LUMA-SH-001", name: "Amber PVC Pump",                  slug: "amber-pvc-pump",                  price_cents: 79000,  cat: :shoes,    collection: "SS27" },
  { sku: "LUMA-BG-002", name: "Black Monogram Flap Bag",         slug: "black-monogram-flap-bag",         price_cents: 142000, cat: :bags,     collection: "SS27" },
  { sku: "LUMA-SH-002", name: "Black Patent Strappy Sandal",     slug: "black-patent-strappy-sandal",     price_cents: 89000,  cat: :shoes,    collection: "SS27" },
  { sku: "LUMA-SH-003", name: "Tan Leather Slingback",           slug: "tan-leather-slingback",           price_cents: 75000,  cat: :shoes,    collection: "SS27" },
  { sku: "LUMA-CO-002", name: "Camel Wool Blazer",               slug: "camel-wool-blazer",               price_cents: 165000, cat: :coats,    collection: "AW26" },
  { sku: "LUMA-SK-001", name: "Olive Pleated Satin Skirt",       slug: "olive-pleated-satin-skirt",       price_cents: 98000,  cat: :skirts,   collection: "SS27" },
  { sku: "LUMA-CO-003", name: "Brown Puff-Sleeve Leather Jacket", slug: "brown-puff-sleeve-leather-jacket", price_cents: 329000, cat: :coats,    collection: "AW26" },
  { sku: "LUMA-TR-001", name: "Ivory Wide-Leg Trousers",         slug: "ivory-wide-leg-trousers",         price_cents: 92000,  cat: :trousers, collection: "SS27" },
  { sku: "LUMA-BG-003", name: "Black Structured Shoulder Bag",   slug: "black-structured-shoulder-bag",   price_cents: 175000, cat: :bags,     collection: "AW26" },
  { sku: "LUMA-BG-004", name: "Black Leather Top-Handle Bag",    slug: "black-leather-top-handle-bag",    price_cents: 219000, cat: :bags,     collection: "AW26" },
  { sku: "LUMA-SH-004", name: "Black Leather Loafers",           slug: "black-leather-loafers",           price_cents: 69000,  cat: :shoes,    collection: "AW26" }
].each do |attrs|
  product = Product.find_or_initialize_by(sku: attrs[:sku])
  product.update!(
    vendor: vendor,
    category: categories[attrs[:cat]],
    name: attrs[:name],
    slug: attrs[:slug],
    price_cents: attrs[:price_cents],
    currency: "EUR",
    status: :active,
    collection: attrs[:collection],
    image_path: "/products/#{attrs[:slug]}.jpeg"
  )
end

puts "Seeding users..."
User.find_or_create_by!(email: "dev@internal.example.com") do |u|
  u.name = "Internal Developer"
  u.user_type = :staff
end

# Curated real feedbacks.
# Each one is linked EXPLICITLY to the products it concerns (a feedback may name
# several pieces) so the associations are guaranteed correct, then run through
# the analysis pipeline to produce its insight + per-product ratings.
puts "Seeding curated feedbacks..."
seed_feedback = lambda do |content:, product_slugs:, location_name: nil, channel: :pos|
  checksum = Digest::SHA256.hexdigest("seed|#{content}")
  next if RawFeedback.exists?(checksum: checksum)

  feedback = RawFeedback.create!(
    source: web_source, synthetic: false, content: content.strip,
    feedback_content_type: :text, channel: channel, language: "en",
    submitted_at: Time.current, processing_status: :pending, checksum: checksum,
    location: location_name && Location.find_by(name: location_name)
  )
  Product.where(slug: product_slugs).each_with_index do |product, i|
    feedback.raw_feedback_products.create!(product: product, position: i)
  end
  FeedbackAnalysisJob.perform_now(feedback)
end

CURATED_FEEDBACKS = [
  {
    # Grey coat (kept) + burgundy dress (declined).
    content: <<~TEXT,
      Mrs. Smith arrived this afternoon and headed straight to the ready-to-wear section.
      She was looking for a long grey coat and immediately fell in love with a formal-cut
      style from the Essentials line. She tried on both the S and M sizes. Although she
      usually wears an S, she felt it was a little too fitted, so she chose the M instead.
      She also tried on the burgundy knit dress displayed in the window, but decided against
      it because she found it too body-hugging. She left the boutique with the coat, which
      happened to be the last one available in size M.
    TEXT
    product_slugs: %w[grey-wool-formal-coat burgundy-knit-maxi-dress],
    location_name: "Paris Boutique"
  },
  {
    # Camel wool jacket (kept) + sage green pleated skirt (declined on length).
    content: <<~TEXT,
      Today, I welcomed Mrs. Lefèvre, a client looking for an elegant outfit for the season.
      After discussing her needs and usual style preferences, I introduced her to several
      pieces from the new collection. She was immediately drawn to a camel wool jacket with a
      slightly oversized silhouette. We compared sizes 38 and 40; although she normally wears a
      size 38, she preferred the comfort and drape of the size 40.
      During her visit, I also suggested a sage green pleated skirt that paired beautifully with
      the jacket. After trying it on, she appreciated the quality of the fabric but felt that the
      length was not quite right for her. We continued exploring the collection and looked at a
      few accessories before she ultimately decided on the jacket. She left very pleased with her
      purchase, especially as it was the last piece available in that size.
    TEXT
    product_slugs: %w[camel-wool-blazer olive-pleated-satin-skirt],
    location_name: "Paris Boutique"
  },
  {
    # Cognac leather jacket (kept) + wide-leg ecru trousers (suggested).
    content: <<~TEXT,
      Today, I assisted Mrs. Martin, who was looking to refresh a few key pieces in
      her wardrobe. As we discussed what she was searching for, I presented several styles that I
      thought would suit her preferences. She was immediately attracted to a cognac leather jacket
      and particularly appreciated its cut and the softness of the leather.
      We tried two different sizes to find the best fit. Although she usually wears a size 36, she
      felt more comfortable in the size 38. During the fitting, I also suggested a pair of wide-leg
      ecru trousers to complete the look. She thought the combination worked very well but
      ultimately decided to focus on the jacket, as it better matched her immediate needs.
      After reviewing the details of the piece and discussing different styling options, she
      confirmed her choice. She left delighted with her purchase and with the service she received
      in the boutique.
    TEXT
    product_slugs: %w[brown-puff-sleeve-leather-jacket ivory-wide-leg-trousers],
    location_name: "Paris Boutique"
  },
  {
    # Loafer — wants a rubber-sole version (durability/grip).
    content: <<~TEXT,
      Mrs. Conti tried on the Riviera Loafer (SKU 772194). While she appreciated the overall
      design, she asked whether a version with a rubber sole existed. She explained that many
      customers in Milan walk extensively and require greater grip and durability during rainy
      periods. She did not purchase but expressed strong interest if such an option became available.
    TEXT
    product_slugs: %w[black-leather-loafers],
    location_name: "Milan Boutique"
  },
  {
    # Closed-back pump — would have preferred a slingback (versatility/comfort).
    content: <<~TEXT,
      Mrs. Rossi visited the Milan boutique looking for an elegant pump for formal occasions. She
      tried on the Babylone Pump and appreciated the silhouette and heel height. However, she
      mentioned that she would have preferred a slingback version, as she finds closed-back pumps
      less versatile and less comfortable during the summer months. Although she liked the design,
      she decided not to proceed with the purchase due to this functional preference.
    TEXT
    product_slugs: %w[amber-pvc-pump],
    location_name: "Milan Boutique"
  },
  {
    # Hand-carry bag — wants a removable shoulder strap (hands-free).
    content: <<~TEXT,
      A customer visited the Rome boutique interested in the Mini Icon Bag (SKU 332184). She loved
      the design and size but asked whether the bag was available with a removable shoulder strap.
      She explained that she often commutes and needs hands-free functionality throughout the day.
      As the current model can only be carried by hand, she decided not to purchase.
    TEXT
    product_slugs: %w[sage-padlock-handbag],
    location_name: "Rome Boutique"
  },
  {
    # Sandal — sole lacked cushioning for prolonged wear.
    content: <<~TEXT,
      A customer entered the Florence boutique specifically looking for sandals from the SS27
      collection. She tried the Riviera Sandal (SKU 921875) and loved the design, but commented
      that the sole lacked cushioning compared to similar products she owns. She left without
      purchasing and suggested adding additional comfort features for prolonged wear.
    TEXT
    product_slugs: %w[black-patent-strappy-sandal],
    location_name: "Florence Boutique"
  },
  {
    # Slingback — out of stock in size 38.
    content: <<~TEXT,
      A returning client visited the Naples boutique intending to purchase the Babylone Slingback
      (SKU 612947) after seeing it online. She requested size 38, but the boutique was out of stock.
      Although highly motivated to purchase, she decided not to place an order and left without buying.
    TEXT
    product_slugs: %w[tan-leather-slingback],
    location_name: "Naples Boutique"
  },
  {
    # Tote — drawn by the campaign + window display, purchased.
    content: <<~TEXT,
      A customer visited the Venice boutique asking specifically about the Venezia Tote (SKU 553281).
      She explained that she had noticed the bag in the latest campaign and later saw it prominently
      displayed in the store window. The product immediately caught her attention and she purchased
      it during the visit.
    TEXT
    product_slugs: %w[black-leather-top-handle-bag],
    location_name: "Venice Boutique"
  },
  {
    # Shoulder bag — same campaign + window display story, purchased.
    content: <<~TEXT,
      A customer visited the Venice boutique asking specifically about the Rodeo bag (SKU 553281).
      She explained that she had noticed the bag in the latest campaign and later saw it prominently
      displayed in the store window. The product immediately caught her attention and she purchased
      it during the visit.
    TEXT
    product_slugs: %w[black-structured-shoulder-bag],
    location_name: "Venice Boutique"
  }
].freeze

CURATED_FEEDBACKS.each { |fb| seed_feedback.call(**fb) }

puts "Seeds complete."
