class Rack::Attack
  # Use Redis as the cache store when available
  # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])

  # Throttle POST /api/v1/events to 60 req/min per token
  throttle("api/events/token", limit: 60, period: 60) do |req|
    if req.path == "/api/v1/events" && req.post?
      # Extract token from JSON body
      begin
        body = req.body.read
        req.body.rewind
        data = JSON.parse(body)
        data["token"]
      rescue
        nil
      end
    end
  end

  # Throttle POST /api/v1/users/activate to 10 req/min per IP
  throttle("api/activate/ip", limit: 10, period: 60) do |req|
    if req.path == "/api/v1/users/activate" && req.post?
      req.ip
    end
  end

  # Throttle POST /auth/send_link to 5 req/min per IP (magic link abuse prevention)
  throttle("auth/send_link/ip", limit: 5, period: 60) do |req|
    if req.path == "/auth/send_link" && req.post?
      req.ip
    end
  end

  # Block obviously bad actors (100+ requests per 10 seconds)
  throttle("req/ip", limit: 100, period: 10) do |req|
    req.ip
  end

  # Return 429 JSON for API routes, HTML for browser routes
  self.throttled_responder = lambda do |env|
    req = Rack::Request.new(env)
    if req.path.start_with?("/api/")
      [
        429,
        { "Content-Type" => "application/json" },
        [{ error: "Rate limit exceeded. Please slow down.", retry_after: 60 }.to_json]
      ]
    else
      [
        429,
        { "Content-Type" => "text/html" },
        ["<h1>Too Many Requests</h1><p>Please wait before trying again.</p>"]
      ]
    end
  end
end
