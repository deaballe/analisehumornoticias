class Rack::Attack
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  throttle("sidekiq/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/sidekiq")
  end
end
