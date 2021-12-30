module AdobeDocApi
  class Configuration
    attr_accessor :client_id, :client_secret, :org_id, :tech_account_id, :private_key_path

    def initialize
      @client_id = nil
      @client_sercret = nil
      @org_id = nil
      @tech_account_id = nil
      @private_key_path = nil
    end
  end
end
