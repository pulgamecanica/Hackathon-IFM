# Single entry point for getting a piece of feedback into the system.
#
# Used by:
#   - Api::V1::FeedbacksController (real + external HTTP posts)
#   - the stub feeder (via that same HTTP endpoint)
#
# Responsibilities:
#   - resolve the Source from its adapter_key (defaults to the stub service)
#   - denormalize the `synthetic` flag from the source's type
#   - dedup on checksum (same content + product set = same feedback)
#   - link products through raw_feedback_products
#   - broadcast the new card to the live dashboard
#   - enqueue FeedbackAnalysisJob for AI processing
#
# Returns a Result with #success?, #raw_feedback, #duplicate?, and #errors.
class FeedbackIngestor
  DEFAULT_ADAPTER_KEY = "stub_service"

  Result = Struct.new(:raw_feedback, :duplicate, :errors, keyword_init: true) do
    def success? = errors.blank?
    def duplicate? = duplicate
  end

  def initialize(params)
    @params = params.to_h.symbolize_keys
  end

  def call
    source = resolve_source
    return failure([ "unknown source adapter_key" ]) unless source

    product_ids = Array(@params[:product_ids]).map(&:to_i).uniq
    checksum = compute_checksum(product_ids)

    existing = RawFeedback.find_by(checksum: checksum)
    return Result.new(raw_feedback: existing, duplicate: true, errors: []) if existing

    raw_feedback = build_feedback(source, checksum)

    RawFeedback.transaction do
      raw_feedback.save!
      attach_products(raw_feedback, product_ids)
    end

    broadcast_new(raw_feedback)
    FeedbackAnalysisJob.perform_later(raw_feedback)

    Result.new(raw_feedback: raw_feedback, duplicate: false, errors: [])
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue ActiveRecord::RecordNotUnique
    # Lost a dedup race — return the row the winner created.
    Result.new(raw_feedback: RawFeedback.find_by(checksum: checksum), duplicate: true, errors: [])
  end

  private

  def resolve_source
    key = @params[:source_adapter_key].presence || DEFAULT_ADAPTER_KEY
    Source.active.find_by(adapter_key: key)
  end

  def build_feedback(source, checksum)
    RawFeedback.new(
      source: source,
      synthetic: source.synthetic?,
      content: @params[:content],
      feedback_content_type: @params[:feedback_content_type].presence || :text,
      channel: @params[:channel].presence || (source.synthetic? ? :synthetic_channel : :api),
      language: @params[:language].presence || "en",
      submitted_at: Time.current,
      processing_status: :pending,
      checksum: checksum,
      metadata: @params[:metadata] || {}
    )
  end

  def attach_products(raw_feedback, product_ids)
    Product.where(id: product_ids).each.with_index do |product, position|
      raw_feedback.raw_feedback_products.create!(product: product, position: position)
    end
  end

  def compute_checksum(product_ids)
    Digest::SHA256.hexdigest("#{@params[:content]}|#{product_ids.sort.join(',')}")
  end

  def broadcast_new(raw_feedback)
    raw_feedback.broadcast_prepend_to(
      "feedback_stream",
      target: "feed",
      partial: "dashboard/raw_feedback",
      locals: { raw_feedback: raw_feedback }
    )
    DashboardStats.broadcast_refresh
  end

  def failure(messages)
    Result.new(raw_feedback: nil, duplicate: false, errors: messages)
  end
end
