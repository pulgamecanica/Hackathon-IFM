require "net/http"
require "json"

namespace :stub do
  desc "POST random synthetic feedback to the ingestion endpoint in real time. " \
       "Usage: rails 'stub:feed[count,interval,host]' (defaults: 25, 1.5s, http://localhost:3000)"
  task :feed, %i[count interval host] => :environment do |_t, args|
    count    = (args[:count] || 25).to_i
    interval = (args[:interval] || 1.5).to_f
    host     = args[:host] || ENV["STUB_HOST"] || "http://localhost:3000"
    uri      = URI.join(host, "/api/v1/feedbacks/ingest")

    if Product.active.none?
      abort "No active products to reference. Run `rails db:seed` first."
    end

    generator = StubFeedbackGenerator.new
    puts "Feeding #{count} synthetic feedback item(s) to #{uri} every #{interval}s…"

    count.times do |i|
      body = generator.payload.merge(source_adapter_key: "stub_service")
      response = post_json(uri, body)
      status = JSON.parse(response.body)["status"] rescue response.code
      puts "  [#{i + 1}/#{count}] #{response.code} #{status} — #{body[:content].truncate(60)}"
      sleep interval unless i == count - 1
    rescue => e
      warn "  [#{i + 1}/#{count}] request failed: #{e.class} #{e.message}"
      sleep interval
    end

    puts "Done."
  end

  desc "Ingest a single synthetic feedback item directly (no HTTP, no server needed)."
  task once: :environment do
    abort "No active products. Run `rails db:seed`." if Product.active.none?
    result = FeedbackIngestor.new(
      StubFeedbackGenerator.payload.merge(source_adapter_key: "stub_service")
    ).call
    puts result.success? ? "Ingested feedback ##{result.raw_feedback.id}" : "Failed: #{result.errors.join(', ')}"
  end
end

def post_json(uri, body)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
  request.body = body.to_json
  http.request(request)
end
