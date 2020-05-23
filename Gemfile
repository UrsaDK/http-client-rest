source 'https://rubygems.org'

gem 'openssl'
gem 'rest-client'

# bundle --without development
group :development do
  gem 'pry', require: false             # An alternative IRB console
  gem 'pry-bond', require: false        # Input completion in pry console
  gem 'pry-byebug', require: false      # Adds step, next, continue & break
  gem 'pry-highlight', require: false   # Highlight and prettify console output
  gem 'pry-rails'                       # Use Pry as your rails console
end

# bundle --without tests
group :tests do
  gem 'rspec', require: false           # Test driven development
  gem 'rubocop', require: false         # Static code analyzer
  gem 'rubocop-rspec', require: false   # Rubocop checker for rspec
  gem 'simplecov', require: false       # Code coverage report generator
end
