# Builds random-but-realistic feedback payloads for the stub feeder.
#
# It only produces the JSON body — it does NOT persist anything. The stub
# feeder (lib/tasks/stub.rake) POSTs these payloads to the ingestion endpoint,
# so the full real-time path (HTTP -> FeedbackIngestor -> job -> broadcast) is
# exercised exactly as a real external source would hit it.
class StubFeedbackGenerator
  # Templates are grouped so the synthetic stream exercises every sub-filter
  # token (material/fit/color/… , stock/delivery , in-store/online/ooh). The
  # analyzer classifies focus + themes from the keywords each line mentions.
  TEMPLATES = [
    # product — material / fit / color / design / comfort / function / quality
    "Absolutely love the %<product>s — the silk fabric is gorgeous and the material feels luxurious.",
    "The fit on the %<product>s runs small and the sizing is off. Disappointed.",
    "Stunning color on the %<product>s, though the shade looked different online.",
    "Gorgeous design on the %<product>s — the silhouette is elegant and modern.",
    "The %<product>s is so comfortable, soft and cosy to wear all day.",
    "Love how versatile and practical the %<product>s is — it works for any function.",
    "The stitching on the %<product>s came apart; the quality and craftsmanship are poor.",
    # distribution — stock availability / delivery delays
    "The %<product>s was out of stock for weeks; the restock and availability are frustrating.",
    "Delivery of the %<product>s was painfully late — shipping delays meant it arrived after my event.",
    # visibility — in store / online campaign / ooh campaign
    "Saw the %<product>s in the boutique; the in-store counter display was beautifully styled.",
    "The online campaign for the %<product>s on the website was stunning and easy to discover.",
    "The %<product>s billboard and the outdoor lookbook poster were misleading versus reality."
  ].freeze

  CHANNELS = %w[web mobile email sms pos].freeze
  LANGUAGES = %w[en en en es fr].freeze # weighted toward English

  # Returns a Hash ready to be sent as the JSON request body.
  def self.payload(...) = new(...).payload

  def initialize(products: nil, locations: nil)
    @products = products || Product.active.to_a
    @locations = locations || Location.where.not(lat: nil).to_a
  end

  def payload
    chosen = sample_products
    {
      content: render_content(chosen),
      product_ids: chosen.map(&:id),
      location_id: @locations.sample&.id,
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

  def render_content(products)
    name = products.first&.name || "product"
    format(TEMPLATES.sample, product: name)
  end
end
