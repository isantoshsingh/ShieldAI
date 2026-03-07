class Rack::Attack
  # Per-token: 60 requests per 60 seconds
  throttle("api/token", limit: 60, period: 60.seconds) do |request|
    if request.path.start_with?("/api/v1/detection_events") && request.post?
      begin
        body = JSON.parse(request.body.read)
        request.body.rewind
        "api/token/#{body['token']}" if body["token"].present?
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Per-IP safety net: 300 requests per 5 minutes
  throttle("api/ip", limit: 300, period: 5.minutes) do |request|
    if request.path.start_with?("/api/v1/detection_events") && request.post?
      request.ip
    end
  end

  # Signup rate limiting: 10 per IP per hour
  throttle("signup/ip", limit: 10, period: 1.hour) do |request|
    if request.path == "/signup" && request.post?
      request.ip
    end
  end

  self.throttled_responder = lambda do |request|
    [429, { "Content-Type" => "application/json" }, [{ error: "rate limit exceeded" }.to_json]]
  end
end
