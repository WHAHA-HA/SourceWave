require 'clockwork'    
require './config/boot'
require './config/environment'

include Clockwork

module Clockwork
  handler do |job|
    Heroku.test
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  every(10.seconds, 'save_logs')
end