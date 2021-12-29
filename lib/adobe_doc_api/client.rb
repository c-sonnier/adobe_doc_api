require 'faraday'
require 'faraday_middleware'
require 'jwt'
require 'openssl'

module AdobeDocApi
  class Client
    JWT_URL = 'https://ims-na1.adobelogin.com/ims/exchange/jwt/'.freeze
    API_ENDPOINT_URL = 'https://cpf-ue1.adobe.io'.freeze
    attr_reader :access_token, :output_ext, :output_format, :poll_url, :content_request

    def initialize(private_key_path:, destination_path:)
      @destination_path = destination_path
      @output_ext = File.extname(destination_path)
      @output_format = @output_ext =~ /docx/ ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : 'application/pdf'

      jwt_payload = {
        'iss' => ENV['adobe_org_id'],
        'sub' => ENV['adobe_tech_account_id'],
        'https://ims-na1.adobelogin.com/s/ent_documentcloud_sdk' => true,
        'aud' => "https://ims-na1.adobelogin.com/c/#{ENV['adobe_client_id']}",
        'exp' => (Time.now.utc + 500).to_i
      }

      rsa_private = OpenSSL::PKey::RSA.new File.read(private_key_path)
      jwt_token = JWT.encode jwt_payload, rsa_private, 'RS256'

      connection = Faraday.new do |conn|
        conn.response :json, content_type: 'application/json'
      end

      response = connection.post JWT_URL do |req|
        req.params['client_id'] = ENV['adobe_client_id']
        req.params['client_secret'] = ENV['adobe_client_secret']
        req.params['jwt_token'] = jwt_token
      end

      @access_token = response.body['access_token']

    end

    def submit(json:, disclosure_file_path:)
      @content_request = {
        "cpf:engine": {
          "repo:assetId": 'urn:aaid:cpf:Service-52d5db6097ed436ebb96f13a4c7bf8fb'
        },
        "cpf:inputs": {
          "documentIn": {
            "dc:format": 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            "cpf:location": 'InputFile0'
          },
          "params": {
            "cpf:inline": {
              "outputFormat": @output_ext.delete('.'),
              "jsonDataForMerge": json
            }
          }
        },
        "cpf:outputs": {
          "documentOut": {
            "dc:format": @output_format.to_s,
            "cpf:location": 'multipartLabel'
          }
        }
      }.to_json

      connection = Faraday.new API_ENDPOINT_URL do |conn|
        conn.request :authorization, 'Bearer', @access_token
        conn.headers['x-api-key'] = ENV['adobe_client_id']
        conn.request :multipart
        conn.request :url_encoded
        conn.response :json, content_type: 'application/json'
      end

      payload = {'contentAnalyzerRequests' => content_request}
      payload[:InputFile0] = Faraday::FilePart.new(disclosure_file_path, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      res = connection.post('/ops/:create', payload)
      @poll_url = res.headers['location']
      poll_for_file(@poll_url)
    end

    def poll_for_file(url)
      poll = Faraday.new do |conn|
        conn.request :authorization, 'Bearer', @access_token
        conn.headers['x-api-key'] = ENV['adobe_client_id']
      end
      counter = 0
      loop do
        sleep(6)
        poll_response = poll.get(url)
        counter += 1
        if poll_response.body.include?('"cpf:status":{"completed":true,"type":"","status":200}')
          write_to_file(poll_response)
          break
        end
        break if counter > 10
      rescue StandardError => e
        # Here we can log if there is a failure from Adobe's response i.e. "Failed to complete"
        raise(e)
      end
    end

    def write_to_file(response)
      temp_file = Tempfile.new([Time.now.to_i.to_s, @output_ext])
      temp_file.write response.body
      temp_file.rewind
      # Read in the raw response and remove the
      my_array = IO.readlines(temp_file.path)
      my_array.pop
      array = my_array.drop(9)
      arry = array.join('')
      File.open(@destination_path, 'wb') { |f| f.write arry.chomp}
      temp_file.close!
    end
  end
end