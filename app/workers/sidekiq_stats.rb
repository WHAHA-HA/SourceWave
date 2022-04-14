class SidekiqStats
  
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  # sidekiq_options :queue => :sidekiq_stats
  
  def perform(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    puts 'getting sidekiq stats'
    if Rails.cache.read(["#{is_do}running_crawls"]).nil?
      if Sidekiq::ScheduledSet.new.size.to_i < 10
        SidekiqStats.delay.start('crawl_id' => crawl_id, 'processor_name' => processor_name)
      end
    elsif Rails.cache.read(["#{is_do}running_crawls"]).include?(crawl_id)
      
      # Rails.cache.write(['expired_rotation'], Rails.cache.read(['running_crawls']).to_a)
      
      processor_name = options['processor_name']
    
      if Sidekiq::ScheduledSet.new.size.to_i < 10
        SidekiqStats.delay.start('crawl_id' => crawl_id, 'processor_name' => processor_name)
      end
    
      running_count = Crawl.running_count_for(crawl_id)
    
      if running_count['processing_count'].to_i > 1
        puts 'SidekiqStats: called start processing from sidekiq stats'
        Link.delay(:queue => "#{is_do}process_links").start_processing
      end
    
      if running_count['expired_count'].to_i > 1
        puts 'SidekiqStats: called verify namecheap from sidekiq stats'
        VerifyNamecheap.delay(:queue => 'verify_domains').start
      end

      Crawl.update_stats(crawl_id, processor_name)

      finished_processing = $redis.smembers("#{is_do}finished_processing/#{crawl_id}")
      if finished_processing.count > 1
        $redis.del(finished_processing)
      end
    
      puts "the number of processing batches left are #{running_count['processing_count']} and the number of expired domains left to be processed are #{running_count['expired_count']} for the crawl #{crawl_id}"
      if running_count['processing_count'].to_i <= 2 && running_count['expired_count'].to_i <= 2
        puts "this crawl has finished all its jobs"
        Api.delay.stop_crawl('crawl_id' => crawl_id, 'processor_name' => processor_name)
      end
      total_minutes_to_run = Rails.cache.read(["#{is_do}crawl/#{crawl_id}/total_minutes_to_run"], raw: true).to_i
      if total_minutes_to_run > 0
        total_minutes_running = ((Time.now - Rails.cache.read(["#{is_do}crawl/#{crawl_id}/start_time"], raw: true).to_time)/60).to_i
        if total_minutes_running > total_minutes_to_run
          puts 'shutting down crawl it has been running for longer than the time specified'
          Api.delay.stop_crawl('crawl_id' => crawl_id, 'processor_name' => processor_name)
        end
      end

    end
  end
  
  def self.start(options={})
    if Rails.cache.read(["#{is_do}running_crawls#"]).nil?
      processor_name = options['processor_name']    
      puts 'scheduling sidekiq and dyno stats'
      SidekiqStats.perform_in(1.minute, options['crawl_id'], 'processor_name' => processor_name)
    elsif Rails.cache.read(["#{is_do}running_crawls"]).include?(options['crawl_id'])
      if Sidekiq::ScheduledSet.new.size.to_i < 10
        puts 'start sidekiq and dyno stats'
        processor_name = options['processor_name']
        puts 'scheduling sidekiq and dyno stats'
        SidekiqStats.perform_in(1.minute, options['crawl_id'], 'processor_name' => processor_name)
      end
    end
  end
  
end