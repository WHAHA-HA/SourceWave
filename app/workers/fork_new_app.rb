class ForkNewApp
  include Sidekiq::Worker
  
  def perform(heroku_app_id, number_of_apps_running, options={})
    processor_name = options['processor_name']
    heroku_app = HerokuApp.using("#{processor_name}").where(id: heroku_app_id).first
    if heroku_app
      crawl_name = "revivecrawler#{heroku_app.crawl_id}"
      puts "the crawl name is #{crawl_name}"
      heroku_app.update(name: crawl_name)
      HerokuPlatform.fork(HerokuPlatform::APP_NAME, crawl_name, heroku_app_id, number_of_apps_running, 'processor_name' => processor_name)
    end
  end
  
  def on_complete(status, options)
    processor_name = options['processor_name']
    batch = HerokuApp.using("#{processor_name}").where(batch_id: "#{options['bid']}").first
    if !batch.nil?
      if batch.status == 'retry'
        puts "heroku app is going to retry recreating"
      else
        puts "heroku app is created with the following id #{options['bid']}"
        # HerokuPlatform.migrate_db(batch.name)
        # UserDashboard.add_running_crawl(crawl.user.user_dashboard.id)
        Api.delay_for(1.minutes).migrate_db(crawl_id: batch.crawl_id, 'processor_name' => processor_name, 'iteration' => 1)
        Api.delay_for(10.minutes).migrate_db(crawl_id: batch.crawl_id, 'processor_name' => processor_name)
        Api.delay_for(11.minutes).start_crawl(crawl_id: batch.crawl_id, 'processor_name' => processor_name)
      end
    end
  end
  
  def self.retry(heroku_app_id, number_of_apps_running, options={})
    processor_name = options['processor_name']
    batch = Sidekiq::Batch.new
    batch.jobs do
      ForkNewApp.perform_async(heroku_app_id, number_of_apps_running,'processor_name' => processor_name)
    end
  end
  
  def self.start(user_id, number_of_apps_running, options={})
    processor_name = options['processor_name']
    
    crawl_to_start = HerokuApp.using("#{processor_name}").where(status: 'pending', user_id: user_id).order(:position).first
    
    batch = Sidekiq::Batch.new
    puts "heroku app bacth id is #{batch.bid}"
    crawl_to_start.update(status: "starting", started_at: Time.now, batch_id: batch.bid)
    batch.on(:complete, ForkNewApp, 'bid' => batch.bid,'processor_name' => processor_name)

    batch.jobs do
      ForkNewApp.perform_async(crawl_to_start.id, number_of_apps_running,'processor_name' => processor_name)
    end
  end
  
end