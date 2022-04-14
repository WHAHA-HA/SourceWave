class DynoStats
  
  def initialize(options={})
    heroku_app = HerokuApp.find(options[:heroku_app_id])
    librato_user = heroku_app.librato_user
    librato_token = heroku_app.librato_token
    @librato = Librato::Metrics.authenticate(librato_user, librato_token)
  end
  
  def metrics(options = {})
    metrics = Librato::Metrics.get_measurements "#{options[:metric]}".to_sym, :count => 1, source: "#{options[:source]}", resolution: 60
    puts "the metrics are #{metrics}"
    unless metrics.empty?
      return metrics["#{options[:source]}"][0]
    end
  end
  
  def self.last_checked?(options = {})
    puts "checking heroku app last update for site with id #{options}"
    if options[:site_id]
      site = Site.find(options[:site_id].to_i)
      heroku_app = site.crawl.heroku_app
      puts "dyno stats for app #{heroku_app.name}"
    elsif options[:heroku_app_id]
      heroku_app = HerokuApp.find(options[:heroku_app_id].to_i)
      puts "dyno stats for app #{heroku_app.name}"
    end
    app_name = heroku_app.name
    heroku_app_last_update = heroku_app.updated_at
    
    if (Time.now - heroku_app_last_update) > 60
      puts 'more than a minute has passed since the dyno stats were checked'
      dynos = []
      ["processlinks", "worker"].each do |dyno|
        memory_stats = Heroku.memory_stats(type: dyno, app_name: app_name, heroku_app_id: heroku_app.id)
        puts "the memory stats for the #{dyno} dyno on the app #{app_name} are #{memory_stats}"
        if memory_stats['green'].count < 2
          dynos << dyno
        end
      end
      unless dynos.empty?
        puts "checked app dyno stats and scaling dynos #{dynos}"
        Heroku.new.scale_dynos(app_name: app_name, dynos: dynos, heroku_app_id: heroku_app.id)
      end
      heroku_app.update(updated_at: Time.now)
    end
  end
  
end