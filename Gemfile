source 'https://code.stripe.com'
source 'https://rubygems.org'

ruby '2.2.0'
gem 'rails' # Choo Choo

# Views
##############

gem 'sass-rails', '~> 4.0.3' # Syntatically Awesome Stylesheets
gem 'uglifier', '>= 1.3.0' # Uglifiy Assets
gem 'coffee-rails', '~> 4.0.0' # It's just JavaScript!
gem 'jquery-rails' # $jQuery
gem 'jquery-ui-rails'# $jQuery UI
gem 'turbolinks' # AJAXED Page Gets
gem 'jbuilder', '~> 2.0' # Build JSON APIs with ease
gem 'bootstrap-sass', '~> 3.3.1' # Pull ourselves up by our..
gem 'bootstrap_form' #Bootstrap forms
gem 'slim' # Shed some syntax

# Libraries
##############

gem 'pg' # The Elephant
gem 'bcrypt', '~> 3.1.7' # Help keep things secret; Use ActiveModel has_secure_password
gem 'autoprefixer-rails'
gem 'nokogiri'
gem 'lazy_high_charts'
gem 'sinatra', require: false
gem 'rubyretriever', github: 'darzuaga/rubyretriever', :branch => 'master'
gem 'domainatrix'
gem 'typhoeus'
gem 'rest-client'
gem 'faraday_middleware', :git => 'git://github.com/Agiley/faraday_middleware.git'
gem 'will_paginate', '~> 3.0.6'
gem 'will_paginate-bootstrap'
gem 'select2-rails'
gem 'unirest'
gem 'premailer-rails'
gem 'acts_as_list'
gem 'bootstrap-datepicker-rails'
gem 'ar-octopus'
gem 'redis-rails'
gem 'chronic'
gem 'clipboard'
gem 'mmenu-rails'
gem "chartkick"

#Digial Ocean management
gem 'droplet_kit'
# Development Things
group :development do

  # Server Thing
  gem 'spring',  group: :development

  # Debuggers
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry'
  gem 'pry-byebug'
  gem 'awesome_print'

end

# APIs
##############

gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem 'majestic_seo_api'
gem 'linkscape'
gem 'platform-api'
gem 'heroku-api'
gem 'librato-metrics'
gem 'unirest'
gem 'magnific-popup-rails'
gem 'whois'

# Server Things
##############

gem 'figaro' # Manage Secrets
gem 'foreman'
gem 'passenger'
# gem 'passenger', '4.0.57'
# gem 'thin' # Use Thin Server
gem 'rails_12factor', group: :production

# If production use sidekiq pro url
if ENV['RACK_ENV'] == 'production'
  gem 'sidekiq-pro', :source => "https://#{ENV['sidekiq_url']}"
else
  #for deployment enable this
  gem 'sidekiq-pro'
  #uncoment only on local development mode
  #gem 'sidekiq-pro', :source => "https://bb35beec:b71e1e88@gems.contribsys.com/"
  #gem 'sidekiq'
end
