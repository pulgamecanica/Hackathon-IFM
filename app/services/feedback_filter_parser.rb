# Turns a natural-language question into a structured set of feedback filters.
#
# This is deterministic and always available — the chatbot uses it to actually
# query the data. (Claude, when configured, only phrases the answer; the
# filtering itself is done here so results are reliable and explainable.)
#
# Recognised filters: sentiment, focus, location, product, synthetic.
class FeedbackFilterParser
  SENTIMENT_HINTS = {
    "negative" => %w[negative unhappy complaint complaints bad poor angry dissatisfied issues problems],
    "positive" => %w[positive happy love loved great good praise delighted],
    "neutral"  => %w[neutral indifferent],
    "mixed"    => %w[mixed conflicted]
  }.freeze

  FOCUS_HINTS = {
    "product"      => %w[product fit fabric quality sizing stitching material design comfort craftsmanship],
    "distribution" => %w[distribution delivery shipping logistics packaging restock stock availability returns],
    "visibility"   => %w[visibility brand website campaign marketing lookbook styling discovery]
  }.freeze

  Filters = Struct.new(:sentiment, :focus, :location_id, :location_name,
                       :product_id, :product_name, :synthetic, keyword_init: true) do
    def describe
      parts = []
      parts << "#{sentiment} sentiment" if sentiment
      parts << "#{focus} feedback" if focus
      parts << "for #{product_name}" if product_name
      parts << "in #{location_name}" if location_name
      parts << (synthetic ? "synthetic only" : "real only") unless synthetic.nil?
      parts.presence&.join(", ") || "all feedback"
    end
  end

  def initialize(question)
    @text = question.to_s.downcase
  end

  def call
    Filters.new(
      sentiment: match_hint(SENTIMENT_HINTS),
      focus: match_hint(FOCUS_HINTS),
      synthetic: synthetic_filter,
      **location_filter,
      **product_filter
    )
  end

  private

  def match_hint(table)
    table.find { |_, words| words.any? { |w| @text.include?(w) } }&.first
  end

  def synthetic_filter
    return true  if @text.match?(/synthetic|fake|stub|simulat/)
    return false if @text.match?(/\breal\b|genuine/)

    nil
  end

  def location_filter
    Location.where.not(lat: nil).each do |loc|
      [ loc.name, loc.city ].compact.each do |label|
        return { location_id: loc.id, location_name: loc.name } if @text.include?(label.downcase)
      end
    end
    {}
  end

  def product_filter
    Product.active.each do |product|
      # Match the full name or any distinctive word (>3 chars) from it.
      words = product.name.downcase.split.select { _1.length > 3 }
      return { product_id: product.id, product_name: product.name } if words.any? { @text.include?(_1) }
    end
    {}
  end
end
