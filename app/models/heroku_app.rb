class HerokuApp < ActiveRecord::Base
  belongs_to :crawl
  has_many :sidekiq_stats
  acts_as_list
end
