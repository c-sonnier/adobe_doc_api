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

## Required ENV variables
```ruby
ENV['adobe_org_id']
ENV['adobe_tech_account_id']
ENV['adobe_client_id']
ENV['adobe_client_secret']
```

## Usage

```ruby
key_path = "../full_path_to/private.key"
doc_path = "../full_path_to/disclosure.docx"
destination = "../full_path_to_output/output.docx"
json_data = { 'DocTag': 'Value', 'DocTag2': 'Value2'}
client = AdobeDocApi::Client.new(private_key_path: key_path, destination_path: destination)
client.submit(json: json_data, disclosure_file_path: doc_path)
```

## Todo
- [ ] Add multipart parsing to improve saving the file from the response
- [ ] Add documentation

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
