# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 4.0.0'

gem 'rake', '~> 13.0'

group :development do
  # RuboCop (+ performance) is the single linter for the whole repo, runner
  # and solutions alike. It surfaces idiom, complexity, and slow-pattern
  # improvements.
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
end

group :test do
  gem 'minitest', '~> 6.0'
  gem 'simplecov', '~> 0.22', require: false
end
