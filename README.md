# AdobeDocApi

This is still a work in progress. Use at your own risk.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adobe_doc_api'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install adobe_doc_api

## Recommended ENV variables 
*Client.new will fallback to use these variables if they are not passed in setup
```ruby
ENV['adobe_org_id']
ENV['adobe_tech_account_id']
ENV['adobe_client_id']
ENV['adobe_client_secret']
```

## Usage

```ruby
key_path = "../full_path_to/private.key"
template_path = "../full_path_to/disclosure.docx"
output_path = "../full_path_to_output/output.docx"
json_data = { 'DocTag': 'Value', 'DocTag2': 'Value2'}

client = AdobeDocApi::Client.new(private_key: key_path)
# Without ENV variables set
# client = AdobeDocApi::Client.new(private_key: key_path, client_id: ENV['adobe_client_id'], client_secret: ENV['adobe_client_secret']org_id: ENV['adobe_org_id'], tech_account_id: ENV['adobe_tech_account_id'], access_token: nil)

client.submit(json: json_data, template: template_path, output: output_path)
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
