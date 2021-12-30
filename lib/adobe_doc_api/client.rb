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
      jwt_payload = {
        "iss" => @org_id,
        "sub" => @tech_account_id,
        "https://ims-na1.adobelogin.com/s/ent_documentcloud_sdk" => true,
        "aud" => "https://ims-na1.adobelogin.com/c/#{@client_id}",
        "exp" => (Time.now.utc + 60).to_i
      }

      rsa_private = OpenSSL::PKey::RSA.new File.read(private_key)

      jwt_token = JWT.encode jwt_payload, rsa_private, "RS256"

      connection = Faraday.new do |conn|
        conn.response :json, content_type: "application/json"
      end
      response = connection.post JWT_URL do |req|
        req.params["client_id"] = @client_id
        req.params["client_secret"] = @client_secret
        req.params["jwt_token"] = jwt_token
      end

      return response.body["access_token"]
    end

    def submit(json:, template:, output:)
      @output = output
      output_format = /docx/.match?(File.extname(@output)) ? "application/vnd.openxmlformats-officedocument.wordprocessingml.document" : "application/pdf"

      content_request = {
        "cpf:engine": {
          "repo:assetId": "urn:aaid:cpf:Service-52d5db6097ed436ebb96f13a4c7bf8fb"
        },
        "cpf:inputs": {
          documentIn: {
            "dc:format": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "cpf:location": "InputFile0"
          },
          params: {
            "cpf:inline": {
              outputFormat: File.extname(@output).delete("."),
              jsonDataForMerge: json
            }
          }
        },
        "cpf:outputs": {
          documentOut: {
            "dc:format": output_format.to_s,
            "cpf:location": "multipartLabel"
          }
        }
      }.to_json

      connection = Faraday.new API_ENDPOINT_URL do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.headers["x-api-key"] = @client_id
        conn.request :multipart
        conn.request :url_encoded
        conn.response :json, content_type: "application/json"
      end

      payload = {"contentAnalyzerRequests" => content_request}
      payload[:InputFile0] = Faraday::FilePart.new(template, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      res = connection.post("/ops/:create", payload)
      status_code = res.body["cpf:status"]["status"].to_i
      @location_url = res.headers["location"]
      raise Error.new(status_code: status_code, msg: res.body["cpf:status"]) unless status_code == 202
      poll_for_file(@location_url)
    end

    private

    def poll_for_file(url)
      connection = Faraday.new do |conn|
        conn.request :authorization, "Bearer", @access_token
        conn.headers["x-api-key"] = @client_id
      end
      counter = 0
      loop do
        sleep(6)
        response = connection.get(url)
        counter += 1
        if response.body.include?('"cpf:status":{"completed":true,"type":"","status":200}')
          @raw_response = response
          return write_to_file(response.body)
        else
          status = JSON.parse(response.body)["cpf:status"]
          raise Error.new(status_code: status["status"], msg: status) if status["status"] != 202
        end
        break if counter > 10
      rescue => e
        # Raise other exceptions
        raise(e)
      end
    end

    def write_to_file(response_body)
      line_index = []
      lines = response_body.split("\r\n")
      lines.each_with_index do |line, i|
        next if line.include?("--Boundary_") || line.match?(/^Content-(Type|Disposition):/) || line.empty? || JSON.parse(line.force_encoding("UTF-8").to_s)
      rescue
        line_index << i
      end
      if line_index.length == 1
        File.open(@output, "wb") { |f| f.write lines.at(line_index[0])}
        true
      else
        false
      end
    end

  end
end
