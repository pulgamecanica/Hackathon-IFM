# Builds random-but-realistic feedback payloads for the stub feeder.
#
# It only produces the JSON body — it does NOT persist anything. The stub
# feeder (lib/tasks/stub.rake) POSTs these payloads to the ingestion endpoint,
# so the full real-time path (HTTP -> FeedbackIngestor -> job -> broadcast) is
# exercised exactly as a real external source would hit it.
class StubFeedbackGenerator
  # Templates are grouped by feedback point so the synthetic stream exercises
  # all three (product / distribution / visibility) — the analyzer classifies
  # focus from the themes each line mentions.
  TEMPLATES = [
    # product
    "Absolutely love the %<product>s — the fabric is gorgeous and the fit is flawless.",
    "The stitching on the %<product>s came apart after one wear. Really disappointed with the quality.",
    "Gorgeous design on the %<product>s but the sizing runs small and the material feels cheap.",
    "The %<product>s has impeccable craftsmanship, the color is stunning. Would buy again.",
    "Not sure about the %<product>s — the comfort is fine but the fabric is a little itchy.",
    # distribution
    "Great value on the %<product>s but delivery was painfully slow and the packaging was torn.",
    "Ordered the %<product>s for an event and shipping was so late it arrived after. Frustrating.",
    "The %<product>s was always out of stock; restock took weeks. The price is also a bit high.",
    "Returns for the %<product>s were seamless and the packaging was luxurious. Lovely experience.",
    # visibility
    "The lookbook for the %<product>s was misleading — it looks nothing like the campaign online.",
    "Loved how the website styled the %<product>s, the styling guide made discovery so easy.",
    "Couldn't find sizing-guide info for the %<product>s anywhere; support was unhelpful.",
    "The brand campaign for the %<product>s is stunning and made me want the whole collection."
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
