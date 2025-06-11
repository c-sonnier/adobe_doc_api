require "net/http"
require "json"

module AdobeDocApi
  class Client
    OAUTH_URL = "https://ims-na1.adobelogin.com/ims/token/v3".freeze
    API_ENDPOINT_URL = "https://pdf-services-ue1.adobe.io/operation/documentgeneration"
    attr_reader :location_url, :raw_response, :client_id, :client_secret, :scopes

    def initialize(client_id: nil, client_secret: nil, scopes: nil)
      @client_id = client_id || AdobeDocApi.configuration.client_id
      @client_secret = client_secret || AdobeDocApi.configuration.client_secret
      @scopes = scopes || AdobeDocApi.configuration.scopes
      @location_url = nil
      @output_file_path = nil
      @raw_response = nil
      @access_token = get_access_token
    end

    def submit(json:, template:, output:)
      @output = output
      @asset_id, upload_uri = upload_presigned_uri
      upload_asset(upload_uri, template: template)
      document_generation(json: json)
    end

    private

    def get_access_token
      url = URI(OAUTH_URL)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.body = "grant_type=client_credentials&client_id=#{@client_id}&client_secret=#{@client_secret}&scope=#{@scopes}"
      response = https.request(request)
      if response.code.to_i != 200
        raise Error.new(status_code: response.code, msg: "Failed to get access token: #{response.body}")
      else
        puts "Access token retrieved successfully"
        JSON.parse(response.body)["access_token"]
      end
    end

    def upload_presigned_uri

      url = URI("https://pdf-services-ue1.adobe.io/assets")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["X-API-Key"] = @client_id
      request["Authorization"] = "bearer #{@access_token}"
      request.body ='{"mediaType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document"}'
      response = https.request(request)

      if response.code.to_i != 200
        raise Error.new(status_code: response.code, msg: "Failed to create asset: #{response.body}")
      else
        puts "Asset created successfully"
        response_body = JSON.parse(response.body)
        asset_id = response_body["assetID"]
        upload_uri = response_body["uploadUri"]
        return asset_id, upload_uri
      end

    end

    def upload_asset(upload_uri, template:)

      # Upload the template to the presigned URI
      url = URI(upload_uri)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Put.new(url)
      request["Content-Type"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      request.body = File.read(template)
      response = https.request(request)
      if response.code.to_i != 200
        raise Error.new(status_code: response.code, msg: "Failed to upload template: #{response.body}")
      else
        puts "Template uploaded successfully"
      end

    end

    def document_generation(json:)
      # Document Generation
      url = URI("https://pdf-services-ue1.adobe.io/operation/documentgeneration")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"
      request["X-API-Key"] = @client_id
      request["Authorization"] = "Bearer #{@access_token}"

      request.body = {"assetID": @asset_id,
                      "outputFormat": "docx",
                      "jsonDataForMerge": json
      }.to_json

      response = https.request(request)

      if response.code.to_i != 201
        raise Error.new(status_code: response.code, msg: "Failed to submit document generation request: #{response.body}")
      else
        status_url = response.header["location"]
        puts "Document Generation submitted successfully"
      end

      # Start polling for the status of the document generation
      poll_status(status_url)
    end

    def poll_status(status_url, timeout: 30)
      # Poll for the generated document
      download_uri = nil
      loop do
        timeout -= 1
        break if timeout <= 0

        # Wait for 5 seconds before checking the status
        url = URI(status_url)
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Get.new(url)
        request["Content-Type"] = "application/json"
        request["X-API-Key"] = @client_id
        request["Authorization"] = "Bearer #{@access_token}"
        response = https.request(request)

        if response.code.to_i != 200
          raise Error.new(status_code: response.code, msg: "Failed to check document generation status: #{response.body}")
        end

        response_body = JSON.parse(response.body)
        puts "Current status: #{response_body['status']}"
        if response_body["status"] == "done"
          download_uri = response_body["asset"]["downloadUri"]
          break
        elsif response_body["status"] == "failed"
          raise Error.new(status_code: response.code, msg: "Document generation failed: #{response.body}")
        else
          puts "Document generation in progress..."
        end
        sleep 1
      end

      # If the download URI is available, proceed to download the document
      if download_uri
        download_output(download_uri: download_uri)
      else
        raise Error.new(status_code: response.code, msg: "Document generation not completed: #{response.body}")
      end

    end

    def download_output(download_uri:)
      # Finally, download the generated document
      url = URI(download_uri)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      response = https.request(request)
      if response.code.to_i != 200
        raise Error.new(status_code: response.code, msg: "Failed to download document: #{response.body}")
      else
        if File.open(@output, "wb") { |f| f.write response.body }
          puts "Document saved successfully to #{@output}"
          return true
        end
      end
    end
  end

end
