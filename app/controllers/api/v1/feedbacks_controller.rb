module Api
  module V1
    # Real-time ingestion endpoint. The stub feeder and any real external
    # source POST feedback here as JSON. Delegates all logic to FeedbackIngestor.
    #
    #   POST /api/v1/feedbacks/ingest
    #   { "content": "...", "product_ids": [1,2], "channel": "web",
    #     "language": "en", "source_adapter_key": "stub_service" }
    class FeedbacksController < ActionController::API
      def create
        result = FeedbackIngestor.new(feedback_params).call

        if result.duplicate?
          render json: { status: "duplicate", id: result.raw_feedback&.id }, status: :ok
        elsif result.success?
          render json: { status: "accepted", id: result.raw_feedback.id }, status: :created
        else
          render json: { status: "error", errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def feedback_params
        params.permit(
          :content, :channel, :language, :feedback_content_type, :source_adapter_key,
          product_ids: [], metadata: {}
        )
      end
    end
  end
end
