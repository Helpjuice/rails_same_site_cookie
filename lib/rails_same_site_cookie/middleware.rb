require 'rails_same_site_cookie/user_agent_checker'

module RailsSameSiteCookie
  class Middleware

    COOKIE_SEPARATOR = "\n".freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      config = RailsSameSiteCookie.configuration
      regex = config.user_agent_regex
      set_cookie = headers['Set-Cookie']
      set_cookie_is_array = set_cookie.is_a?(Array)
      if (regex.nil? or regex.match(env['HTTP_USER_AGENT'])) and not (set_cookie.nil? or (set_cookie_is_array ? set_cookie.empty? : set_cookie.strip == ''))
        parser = UserAgentChecker.new(env['HTTP_USER_AGENT'])
        if parser.send_same_site_none? && config.send_same_site_none?(env)
          cookies = set_cookie_is_array ? set_cookie : set_cookie.split(COOKIE_SEPARATOR)
          ssl = Rack::Request.new(env).ssl?

          cookies.each do |cookie|
            next if cookie == '' or cookie.nil?
            next if !ssl && parser.chrome? # https://www.chromestatus.com/feature/5633521622188032

            if ssl and not cookie =~ /;\s*secure/i
              cookie << '; Secure'
            end

            unless cookie =~ /;\s*samesite=/i
              cookie << '; SameSite=None'
            end

          end

          headers['Set-Cookie'] = set_cookie_is_array ? cookies : cookies.join(COOKIE_SEPARATOR)
        end
      end

      [status, headers, body]
    end

  end
end
