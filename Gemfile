# frozen_string_literal: true

ruby File.read('.ruby-version').strip
source 'https://rubygems.org'

gem 'openssl'
gem 'rest-client'

# bundle --without development --without test
%i[development test].tap do |groups|
  gem 'pry', group: groups, require: true
  gem 'pry-byebug', group: groups, require: false
end

# bundle --without test
group :test do
  gem 'rspec', require: false           # Test driven development
  gem 'rubocop', require: false         # Static code analyzer
  gem 'rubocop-rspec', require: false   # Rubocop checker for rspec
  gem 'simplecov', require: false       # Code coverage report generator
end
