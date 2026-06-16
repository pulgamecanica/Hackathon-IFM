# Builds random-but-realistic feedback payloads for the stub feeder.
#
# It only produces the JSON body — it does NOT persist anything. The stub
# feeder (lib/tasks/stub.rake) POSTs these payloads to the ingestion endpoint,
# so the full real-time path (HTTP -> FeedbackIngestor -> job -> broadcast) is
# exercised exactly as a real external source would hit it.
class StubFeedbackGenerator
  TEMPLATES = [
    "Absolutely love the %<product>s, works perfectly and arrived fast.",
    "The %<product>s broke after a week. Really disappointed with the quality.",
    "Decent %<product>s for the price, though the packaging was awful.",
    "Great value on the %<product>s but delivery was painfully slow.",
    "The %<product>s is reliable and the support team was super helpful.",
    "Not sure about the %<product>s — it's fine but nothing amazing.",
    "Excellent build quality on the %<product>s, would buy again.",
    "Hate to say it, but the %<product>s feels cheap and useless.",
    "Smooth experience with the %<product>s, though the price is a bit high.",
    "The %<product>s arrived defective, but the refund was quick and easy."
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
