require "faraday"
require "faraday_middleware"
require "jwt"
require "openssl"

module AdobeDocApi
  class Client
    JWT_URL = "https://ims-na1.adobelogin.com/ims/exchange/jwt/".freeze
    API_ENDPOINT_URL = "https://cpf-ue1.adobe.io".freeze

    attr_reader :access_token, :location_url, :raw_response, :client_id, :client_secret, :org_id, :tech_account_id

    def initialize(private_key: nil, client_id: nil, client_secret: nil, org_id: nil, tech_account_id: nil, access_token: nil)
      # TODO Need to validate if any params are missing and return error
      @client_id = client_id || AdobeDocApi.configuration.client_id
      @client_secret = client_secret || AdobeDocApi.configuration.client_secret
      @org_id = org_id || AdobeDocApi.configuration.org_id
      @tech_account_id = tech_account_id || AdobeDocApi.configuration.tech_account_id
      @private_key_path = private_key || AdobeDocApi.configuration.private_key_path
      @location_url = nil
      @output_file_path = nil
      @raw_response = nil
      @access_token = access_token || get_access_token(@private_key_path)
    end

    def get_access_token(private_key)
      # TODO: JWT token deprecated and will stop working Jan 1, 2024.
      # jwt_payload = {
      #   "iss" => @org_id,
      #   "sub" => @tech_account_id,
      #   "https://ims-na1.adobelogin.com/s/ent_documentcloud_sdk" => true,
      #   "aud" => "https://ims-na1.adobelogin.com/c/#{@client_id}",
      #   "exp" => (Time.now.utc + 60).to_i
      # }
      #
      # rsa_private = OpenSSL::PKey::RSA.new File.read(private_key)
      #
      # jwt_token = JWT.encode jwt_payload, rsa_private, "RS256"
      #
      connection = Faraday.new do |conn|
        conn.response :json, content_type: "application/json"
      end
      # response = connection.post JWT_URL do |req|
      #   req.params["client_id"] = @client_id
      #   req.params["client_secret"] = @client_secret
      #   req.params["jwt_token"] = jwt_token
      # end
      scopes = "openid, DCAPI, AdobeID"

      response = connection.post "https://ims-na1.adobelogin.com/ims/token/v3" do |req|
        req.params["client_id"] = @client_id
        req.body = "client_secret=p8e-KHU2dpvy7gICy3CK3VbElm-sKPY9_c3C&grant_type=client_credentials&scope=#{scopes}"
      end
      return response.body["access_token"]
    end

    def get_asset_id
      # Create new asset ID to get upload pre-signed Uri
      connection = Faraday.new do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.headers["x-api-key"] = @client_id
        conn.headers["Content-Type"] = ""
        conn.response :json, content_type: "application/json"
      end
      response = connection.post "https://pdf-services.adobe.io/assets" do |req|
        req.body = {mediaType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"}.to_json
        req.headers["Content-Type"] = "application/json"
      end
      # Return pre-signed uploadUri and assedID
      return response.body["assetID"], response.body["uploadUri"]
    end

    def submit(json:, template:, output:)
      asset_id, upload_uri = get_asset_id

      # Upload template to asset created earlier.
      response = Faraday.put upload_uri do |req|
        req.headers["Content-Type"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        req.body = File.binread(template)
      end
      raise("Failed to upload template.") if response.status.to_i != 200

      # Post JSON Data for Merge to documentGeneration
      content_request = {
        assetID: asset_id,
        outputFormat: File.extname(output).delete("."),
        jsonDataForMerge: json
      }.to_json
      payload = content_request
      connection = Faraday.new do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.headers["x-api-key"] = @client_id
      end
      res = connection.post "https://pdf-services-ue1.adobe.io/operation/documentgeneration" do |req|
        req.body = payload
        req.headers["Content-Type"] = "application/json"
      end
      # TODO need to check status of response
      # Begin polling for status of file
      poll_for_file(res.headers["location"], output)
    end

    private

    def poll_for_file(url, output)
      connection = Faraday.new do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.headers["x-api-key"] = @client_id
      end
      counter = 0
      loop do
        sleep(6)
        response = connection.get(url)
        counter += 1
        if JSON.parse(response.body)["status"] == "done"
          file_response = Faraday.get JSON.parse(response.body)["asset"]["downloadUri"]
          return true if File.open(output, "wb") { |f| f.write file_response.body}
        else
          status = JSON.parse(response.body)["status"]
          raise Error.new(status_code: status["status"], msg: status) if status["status"] != 202
        end
        break if counter > 10
      rescue => e
        # Raise other exceptions
        raise(e)
      end
    end

  end
end
