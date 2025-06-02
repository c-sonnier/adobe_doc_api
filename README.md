# AdobeDocApi

This is still a work in progress and breaking changes may be made, but I will do my best to update the README when features have been changed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adobe_doc_api'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install adobe_doc_api

## Configuration
```ruby
AdobeDocApi.configure do |config|
    config.client_id = nil
    config.client_secret = nil
    config.scopes = nil
end
```
### Recommended configuration if using Rails 6+
```ruby
AdobeDocApi.configure do |config|
    config.client_id = Rails.application.credentials.dig(:adobe_doc, :client_id)
    config.client_secret = Rails.application.credentials.dig(:adobe_doc, :client_secret)
    config.scopes = Rails.application.credentials.dig(:adobe_doc, :scopes)
end
```
## Usage

```ruby
template_path = "../full_path_to/disclosure.docx"
output_path = "../full_path_to_output/output.docx"
json_data = { 'DocTag': 'Value', 'DocTag2': 'Value2'}

client = AdobeDocApi::Client.new
client.submit(json: json_data, template: template_path, output: output_path)
# returns true or false if file was saved to output_path
```
### Usage without configuration
```ruby
client = AdobeDocApi::Client.new(client_id: adobe_client_id,
                                 client_secret: adobe_client_secret,
                                 scopes: adobe_scopes,
                                 access_token: nil)
```
## Todo
- [x] Add multipart parsing to improve saving the file from the response
- [ ] Add documentation

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
