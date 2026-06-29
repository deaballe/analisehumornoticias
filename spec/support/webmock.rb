require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before do
    stub_const("DEEPSEEK_CLIENT", instance_double(OpenAI::Client, chat: {}))
  end
end
