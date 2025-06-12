# AdobeDocApi

A Ruby client for the [Adobe Document Generation API](https://developer.adobe.com/document-services/docs/apis/#tag/Document-Generation). It wraps the HTTP calls required to send a Word template and JSON data to Adobe and download the generated document.

## How it works

1. **OAuth authentication** – the client exchanges your `client_id`, `client_secret` and `scopes` for an access token using Adobe's OAuth server-to-server flow.
2. **Upload template** – the SDK requests a presigned upload URL, then uploads your Word template to that URL.
3. **Generate document** – it submits the Document Generation job with your JSON payload and polls Adobe for completion.
4. **Download output** – once the job is complete, the generated file (DOCX) is downloaded to the path you specify.

The gem hides these steps behind a small API so you can focus on supplying the template and data.

## Installation

Add to your application's `Gemfile` and run `bundle install`:

```ruby
gem 'adobe_doc_api'
```

Or install it directly with:

```shell
gem install adobe_doc_api
```

## Configuration

Set your Adobe credentials before using the client:

```ruby
AdobeDocApi.configure do |config|
  config.client_id = YOUR_CLIENT_ID
  config.client_secret = YOUR_CLIENT_SECRET
  config.scopes = "your\:scopes" # e.g. 'openid,AdobeID,read_organizations'
end
```

If you are on Rails, you may want to load these values from encrypted credentials:

```ruby
AdobeDocApi.configure do |config|
  config.client_id     = Rails.application.credentials.dig(:adobe_doc, :client_id)
  config.client_secret = Rails.application.credentials.dig(:adobe_doc, :client_secret)
  config.scopes        = Rails.application.credentials.dig(:adobe_doc, :scopes)
end
```

## Usage

```ruby
template_path = "/full/path/to/template.docx"
output_path   = "/full/path/to/output.docx"
json_data     = { DocTag: "Value", DocTag2: "Value2" }

client = AdobeDocApi::Client.new
client.submit(json: json_data, template: template_path, output: output_path)
# => true when the file is saved to `output_path`
```

You can also pass credentials directly when creating the client:

```ruby
client = AdobeDocApi::Client.new(client_id: "id", client_secret: "secret", scopes: "scopes")
```

For information on the API responses and parameters see the [official Adobe Services API documentation](https://developer.adobe.com/document-services/docs/apis/#tag/Document-Generation).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

