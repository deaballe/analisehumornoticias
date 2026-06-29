DEEPSEEK_CLIENT = OpenAI::Client.new(
  access_token: ENV.fetch("DEEPSEEK_API_KEY", "dummy"),
  uri_base: ENV.fetch("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
)
