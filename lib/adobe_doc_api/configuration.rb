module AdobeDocApi
  class Configuration
    attr_accessor :client_id, :client_secret, :scopes

    def initialize
      @client_id = nil
      @client_secret = nil
      @scopes = nil
    end
  end
end
