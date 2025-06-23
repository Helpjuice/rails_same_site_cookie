RSpec.describe RailsSameSiteCookie::Middleware do
  let(:app) { MockRackApp.new }
  subject { described_class.new(app) }

  context "when configured with a regex" do
    let(:request) { Rack::MockRequest.new(subject) }
    before(:each) do
      RailsSameSiteCookie.configure do |config|
        config.user_agent_regex = /StrongrFastrApp/
      end
    end

    it "adds SameSite=None to cookies for requests whose UA matches regex" do
      response = request.post("/some/path", 'HTTP_USER_AGENT' => 'StrongrFastrApp')
      expect(response['Set-Cookie']).to match(/;\s*samesite=none/i)
    end

    it "doesn't add SameSite=None if request is missing regex" do
      response = request.post("/some/path")
      expect(response['Set-Cookie']).not_to match(/;\s*samesite=none/i)
    end
  end

  context "when configured without a regex" do
    let(:request) { Rack::MockRequest.new(subject) }
    before(:each) do
      RailsSameSiteCookie.configure do |config|
        config.user_agent_regex = nil
      end
    end

    it "adds SameSite=None to cookies for all requests" do
      response = request.post("/some/path", 'HTTP_USER_AGENT' => '')
      expect(response['Set-Cookie']).to match(/;\s*samesite=none/i)
    end

  end

  context "when custom check is provided" do
    let(:request) { Rack::MockRequest.new(subject) }
    before(:each) do
      RailsSameSiteCookie.configure do |config|
        config.custom_check = ->(env) { env['HTTP_USER_AGENT'] == 'CustomUserAgent' }
      end
    end

    it "adds SameSite=None to cookies when custom check passes" do
      response = request.post("/some/path", 'HTTP_USER_AGENT' => 'CustomUserAgent')
      expect(response['Set-Cookie']).to match(/;\s*samesite=none/i)
    end

    it "does not add SameSite=None when custom check fails" do
      response = request.post("/some/path", 'HTTP_USER_AGENT' => 'DifferentUserAgent')
      expect(response['Set-Cookie']).not_to match(/;\s*samesite=none/i)
    end
  end

end