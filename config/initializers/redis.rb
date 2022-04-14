if ENV['REDISTOGO_URL'].present?
  $redis = Redis.new(:url => ENV['REDISTOGO_URL'])
else
  if Rails.env.development?
    $redis = Redis.new(:url=> 'redis://127.0.0.1:6379')
  else
    $redis = Redis.new(:url => ENV['REDISCLOUD_URL'])
  end

end