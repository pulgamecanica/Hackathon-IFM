# Builds random-but-realistic feedback payloads for the stub feeder.
#
# It only produces the JSON body — it does NOT persist anything. The stub
# feeder (lib/tasks/stub.rake) POSTs these payloads to the ingestion endpoint,
# so the full real-time path (HTTP -> FeedbackIngestor -> job -> broadcast) is
# exercised exactly as a real external source would hit it.
#
# The scenarios mirror the curated boutique narratives seeded in db/seeds.rb:
# a client visits a named boutique, tries a specific piece from its seasonal
# collection, and the seller records the outcome. Each scenario still embeds the
# StubAiAnalyzer keyword tokens for a given focus + sentiment, so the synthetic
# stream keeps exercising every dashboard sub-filter (focus / theme / sentiment).
class StubFeedbackGenerator
  CLIENTS = [
    "Mrs. Rossi", "Mrs. Conti", "Ms. Laurent", "Mrs. Moreau", "Mr. Bianchi",
    "Mrs. Ricci", "Ms. Dubois", "Mrs. Esposito", "Mrs. Romano", "Ms. Fontaine",
    "Mrs. Greco", "Ms. Lefèvre"
  ].freeze

  SIZE_PAIRS = [ %w[36 38], %w[38 40], %w[40 42], %w[S M], %w[M L] ].freeze

  # Placeholders available to every scenario: client, city, product, collection,
  # size, size_alt. `format` ignores the ones a scenario doesn't use.
  SCENARIOS = [
    # ---- product · positive ----
    "%{client} visited the %{city} boutique and was immediately drawn to the %{product} from the " \
    "%{collection} collection. She loved the elegant silhouette and the cut, and found the fabric soft " \
    "and impeccable. After comparing sizes %{size} and %{size_alt}, she chose the %{size_alt} and left " \
    "delighted with the quality and craftsmanship.",

    "%{client} stopped by the %{city} boutique looking for an everyday piece and tried the %{product} " \
    "from the %{collection} collection. She found it remarkably comfortable and cosy, praising how soft " \
    "and versatile it felt for daily wear. She purchased it on the spot, calling it gorgeous and practical.",

    "%{client} examined the %{product} from the %{collection} collection at the %{city} boutique and " \
    "admired the impeccable craftsmanship and durable seams. She felt the quality justified the price and " \
    "bought it, describing the material as luxurious.",

    # ---- product · negative ----
    "%{client} came to the %{city} boutique for the %{product} from the %{collection} collection but was " \
    "disappointed by the fit, which ran small and felt poorly tailored. She also noticed the stitching " \
    "and seams looked flimsy, questioning the overall quality, and left without purchasing.",

    "%{client} examined the %{product} from the %{collection} collection at the %{city} boutique and felt " \
    "let down. She described the material as cheap and itchy and thought the colour looked faded compared " \
    "with the online shade. Disappointed, she decided against the purchase.",

    # ---- product · mixed ----
    "%{client} tried the %{product} from the %{collection} collection at the %{city} boutique. She loved " \
    "the design and the elegant cut; however, she felt the fit was not quite right and the length did not " \
    "suit her. She appreciated the quality but ultimately did not purchase.",

    # ---- distribution · negative ----
    "%{client} visited the %{city} boutique specifically for the %{product} from the %{collection} " \
    "collection. Unfortunately it was out of stock in size %{size}; the restock and availability have been " \
    "a recurring frustration. Highly motivated to buy, she left disappointed without placing an order.",

    "%{client} returned to the %{city} boutique about the %{product} from the %{collection} collection she " \
    "had ordered. The delivery was late and the shipping delay meant it arrived well after her event. She " \
    "was disappointed by the logistics despite loving the piece.",

    # ---- visibility · positive ----
    "%{client} came into the %{city} boutique asking specifically about the %{product} from the " \
    "%{collection} collection. She had noticed it in the latest online campaign and on the website, and " \
    "found the digital styling stunning and easy to discover. She purchased it during her visit.",

    "%{client} visited the %{city} boutique where the %{product} from the %{collection} collection was " \
    "beautifully styled on the in-store counter display. The boutique presentation caught her eye " \
    "immediately, and she described it as elegant and chic before purchasing.",

    # ---- visibility · negative ----
    "%{client} mentioned to the %{city} boutique team that the %{product} from the %{collection} " \
    "collection billboard and the outdoor lookbook poster felt misleading versus the piece in person. She " \
    "found the print campaign overpromised and left unconvinced.",

    # ---- product · negative (comfort / function) ----
    "%{client} tried the %{product} from the %{collection} collection at the %{city} boutique but found it " \
    "neither comfortable nor practical for daily wear. She felt the cut restricted movement and the piece " \
    "seemed overpriced, so she declined."
  ].freeze

  CHANNELS = %w[pos pos web mobile email].freeze # weighted toward in-boutique
  LANGUAGES = %w[en en en es fr].freeze          # weighted toward English

  # Returns a Hash ready to be sent as the JSON request body.
  def self.payload(...) = new(...).payload

  def initialize(products: nil, locations: nil)
    @products = products || Product.active.to_a
    @locations = locations || Location.where.not(lat: nil).to_a
  end

  def payload
    chosen = sample_products
    location = @locations.sample
    {
      content: render_content(chosen, location),
      product_ids: chosen.map(&:id),
      location_id: location&.id,
      channel: CHANNELS.sample,
      language: LANGUAGES.sample
    }
  end

  private

  # Most feedback is about one product; occasionally two (multi-product feedback).
  def sample_products
    return [] if @products.empty?

    count = rand < 0.8 ? 1 : 2
    @products.sample([ count, @products.size ].min)
  end

  # Compose a boutique narrative around the (primary) product and the boutique it
  # is tagged to, so the text stays coherent with location_id and the collection.
  def render_content(products, location)
    product = products.first
    return SCENARIOS.sample if product.nil?

    sizes = SIZE_PAIRS.sample
    format(
      SCENARIOS.sample,
      client: CLIENTS.sample,
      city: location&.city.presence || "flagship",
      product: product.name,
      collection: product.collection.presence || "current",
      size: sizes.first,
      size_alt: sizes.last
    )
  end
end
