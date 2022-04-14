require 'domainatrix'

class ProcessLinks
  
  include Sidekiq::Worker
  sidekiq_options :queue => :process_links
  sidekiq_options :retry => 3
  
  def perform(l, site_id, found_on, domain, crawl_id, options={})
    processor_name = options['processor_name']
    request = Typhoeus::Request.new(l, method: :head, followlocation: true, timeout: 15)
    request.on_complete do |response|
      
      internal = l.include?("#{domain}") ? true : false
      if internal == true && "#{response.code}" == '404'
        Rails.cache.increment(["crawl/#{crawl_id}/broken_domains"])
        Rails.cache.increment(["site/#{site_id}/broken_domains"])
        Page.using("#{processor_name}").create(status_code: "#{response.code}", url: "#{l}", internal: internal, site_id: site_id, found_on: "#{found_on}", crawl_id: crawl_id)
      elsif internal == false
        if "#{response.code}" == '404'
          Rails.cache.increment(["crawl/#{crawl_id}/broken_domains"])
          Rails.cache.increment(["site/#{site_id}/broken_domains"])
          Page.using("#{processor_name}").create(status_code: "#{response.code}", url: "#{l}", internal: internal, site_id: site_id, found_on: "#{found_on}", crawl_id: crawl_id)
        elsif "#{response.code}" == '0'
          
          redis_id = ("expired-#{crawl_id}-"+SecureRandom.hex+Time.now.to_i.to_s)
          $redis.sadd "all_ids/#{crawl_id}", redis_id
          puts "ProcessLinks: the redis id is #{redis_id}"
          $redis.set(redis_id, {status_code: "#{response.code}", url: "#{l}", internal: internal, site_id: site_id, found_on: "#{found_on}", crawl_id: crawl_id, processor_name: processor_name}.to_json)
          
          # expired_ids_array = Rails.cache.read(["crawl/#{crawl_id}/expired_ids"]).to_a
          $redis.sadd "all_expired_ids", redis_id
          # puts "ProcessLinks: the number of expired ids are #{expired_ids_array.count} for the crawl #{crawl_id}"
          # Rails.cache.write(["crawl/#{crawl_id}/expired_ids"], expired_ids_array.push(redis_id))
          
          
          if $redis.smembers('all_expired_ids').count <= 1
            puts "ProcessLinks: calling start start method"
            VerifyNamecheap.delay(:queue => 'verify_domains').start
          end
          
        end
      end
    end
    begin
      Timeout::timeout(10) do
        request.run
      end
    rescue Timeout::Error
      puts "slow response from #{l}"
    end
  end
  
  def on_complete(status, options={})
    puts "finished processing batch #{options} and calling new batch to process"
    
    if Sidekiq::ScheduledSet.new.size.to_i < 1
      puts "no sidekiq stats currently running starting up"
      SidekiqStats.delay.start('crawl_id' => options['crawl_id'], 'processor_name' => options['processor_name'])
    end
    
    running_crawls = Rails.cache.read(['running_crawls']).to_a
    
    if running_crawls.count > 0
      if running_crawls.map{|c|Crawl.running_count_for(c)}.sum{|c|c['processing_count']} > 0
        puts "ProcessLinks: calling process link"
        Link.delay(:queue => 'process_links').start_processing
      end
    end
    $redis.sadd "finished_processing/#{options['crawl_id']}", options["redis_id"]
    
    processor_name = options['processor_name']
    
    total_site_count = Rails.cache.read(["site/#{options['site_id']}/processing_batches/total"], raw: true).to_i
    total_site_running = Rails.cache.decrement(["site/#{options['site_id']}/processing_batches/running"])
    total_site_finished = Rails.cache.increment(["site/#{options['site_id']}/processing_batches/finished"])

    total_crawl_count = Rails.cache.read(["crawl/#{options['crawl_id']}/processing_batches/total"], raw: true).to_i
    total_crawl_running = Rails.cache.decrement(["crawl/#{options['crawl_id']}/processing_batches/running"])
    total_crawl_finished = Rails.cache.increment(["crawl/#{options['crawl_id']}/processing_batches/finished"])
    
    progress = (total_crawl_finished.to_f/total_crawl_count.to_f)*100.to_f
    Rails.cache.write(["crawl/#{options['crawl_id']}/progress"], progress, raw: true)
    
    
    if total_site_running <= 0
      
      puts 'updating site stats'
      
      crawl_urls_found = "crawl/#{options['crawl_id']}/urls_found"
      crawl_expired_domains = "crawl/#{options['crawl_id']}/expired_domains"
      crawl_broken_domains = "crawl/#{options['crawl_id']}/broken_domains"
      
      site_urls_found = "site/#{options['site_id']}/total_site_urls"
      site_expired_domains = "site/#{options['site_id']}/expired_domains"
      site_broken_domains = "site/#{options['site_id']}/broken_domains"
      
      stats = Rails.cache.read_multi(crawl_urls_found, crawl_expired_domains, crawl_broken_domains, site_urls_found, site_expired_domains, site_broken_domains, raw: true)
      
      Site.using("#{processor_name}").update(options['site_id'], processing_status: 'finished', total_urls_found: stats[site_urls_found].to_i, total_expired: stats[site_expired_domains].to_i, total_broken: stats[site_broken_domains].to_i)
      Crawl.using("#{processor_name}").update(options['crawl_id'], total_urls_found: stats[crawl_urls_found].to_i, total_broken: stats[crawl_broken_domains].to_i, total_expired: stats[crawl_expired_domains].to_i)
    else
      puts 'do something else'
    end

  end
  
end