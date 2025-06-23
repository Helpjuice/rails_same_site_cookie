module RailsSameSiteCookie
  class Configuration
    attr_accessor :user_agent_regex, :custom_check

    def initialize
      @user_agent_regex = nil
    end

    def send_same_site_none?(env)
      return false if user_agent_regex && env['HTTP_USER_AGENT'] !~ user_agent_regex

      return false if custom_check && !custom_check.call(env)

      true
    end
  end
end