require 'retriever'
require 'domainatrix'

class Crawl < ActiveRecord::Base
  
  attr_accessor :hours, :minutes
  
  belongs_to :user
  has_many :sites
  has_many :pages, through: :sites
  has_many :links, through: :sites
  has_many :gather_links_batches, through: :sites
  has_many :process_links_batches, through: :sites
  has_one :heroku_app
  
  GOOGLE_PARAMS = ['links', 'resources', 'intitle:links', 'intitle:resources', 'intitle:sites', 'intitle:websites', 'inurl:links', 'inurl:resources', 'inurl:sites', 'inurl:websites', '"useful links"', '"useful resources"', '"useful sites"', '"useful websites"', '"recommended links"', '"recommended resources"', '"recommended sites"', '"recommended websites"', '"suggested links"', '"suggested resources"', '"suggested sites"', '"suggested websites"', '"more links"', '"more resources"', '"more sites"', '"more websites"', '"favorite links"', '"favorite resources"', '"favorite sites"', '"favorite websites"', '"related links"', '"related resources"', '"related sites"', '"related websites"', 'intitle:"useful links"', 'intitle:"useful resources"', 'intitle:"useful sites"', 'intitle:"useful websites"', 'intitle:"recommended links"', 'intitle:"recommended resources"', 'intitle:"recommended sites"', 'intitle:"recommended websites"', 'intitle:"suggested links"', 'intitle:"suggested resources"', 'intitle:"suggested sites"', 'intitle:"suggested websites"', 'intitle:"more links"', 'intitle:"more resources"', 'intitle:"more sites"', 'intitle:"more websites"', 'intitle:"favorite links"', 'intitle:"favorite resources"', 'intitle:"favorite sites"', 'intitle:"favorite websites"', 'intitle:"related links"', 'intitle:"related resources"', 'intitle:"related sites"', 'intitle:"related websites"', 'inurl:"useful links"', 'inurl:"useful resources"', 'inurl:"useful sites"', 'inurl:"useful websites"', 'inurl:"recommended links"', 'inurl:"recommended resources"', 'inurl:"recommended sites"', 'inurl:"recommended websites"', 'inurl:"suggested links"', 'inurl:"suggested resources"', 'inurl:"suggested sites"', 'inurl:"suggested websites"', 'inurl:"more links"', 'inurl:"more resources"', 'inurl:"more sites"', 'inurl:"more websites"', 'inurl:"favorite links"', 'inurl:"favorite resources"', 'inurl:"favorite sites"', 'inurl:"favorite websites"', 'inurl:"related links"', 'inurl:"related resources"', 'inurl:"related sites"', 'inurl:"related websites"', 'list of links', 'list of resources', 'list of sites', 'list of websites', 'list of blogs', 'list of forums']
  
  def self.stop_crawl(crawl_id, options={})
    puts "stop crawl method for the crawl #{crawl_id} in the processor #{options["processor_name"]}"
    processor_name = options["processor_name"]
    crawl = Crawl.using("#{processor_name}").where(id: crawl_id).first
    puts "here is the crawl to stop #{crawl_id} on the processor #{processor_name}"
    if crawl && crawl.status != 'finished'
      status = options['status'].nil? ? 'finished' : options['status']
      heroku_app = crawl.heroku_app
      
      if heroku_app
        heroku_app.update(status: status)
      end
      
      crawl.update(status: status)
      heroku = HerokuPlatform.new
      heroku.delete_app("revivecrawler#{crawl_id}")
      
    end
  end

  #stopping do crawler
  def self.do_stop_crawl(crawl_id, options={})
    puts "stop crawl method for the crawl #{crawl_id} in the processor #{options["processor_name"]}"
    processor_name = options["processor_name"]
    crawl = Crawl.using("#{processor_name}").where(id: crawl_id).first
    puts "here is the crawl to stop #{crawl_id} on the processor #{processor_name}"
    if crawl && crawl.status != 'finished'
      status = options['status'].nil? ? 'finished' : options['status']
      heroku_app = crawl.heroku_app

      if heroku_app
        heroku_app.update(status: status)
      end

      crawl.update(status: status)
      heroku = HerokuPlatform.new
      heroku.delete_app("revivecrawler#{crawl_id}")

    end
  end
  
  def self.start_crawl(options = {})
    processor_name = options['processor_name']
    puts "start_crawl: the processor name is #{processor_name}"
    crawl = Crawl.using("#{processor_name}").find(options["crawl_id"].to_i)
    if crawl
      puts "crawl total minutes are #{crawl.total_minutes.to_i}"
      crawl.setCrawlStartingVariables('total_minutes' => crawl.total_minutes.to_i)
      if crawl.crawl_type == 'url_crawl'
        Crawl.save_new_sites(crawl.id, 'processor_name' => processor_name)
      elsif crawl.crawl_type == 'keyword_crawl'
        SaveSitesFromGoogle.start_batch(crawl.id, 'processor_name' => processor_name)
      end
    end
  end

  #start DO crawler
  def self.start_crawl(options = {})
    processor_name = options['processor_name']
    puts "start_crawl: the processor name is #{processor_name}"
    crawl = Crawl.using("#{processor_name}").find(options["crawl_id"].to_i)
    if crawl
      puts "crawl total minutes are #{crawl.total_minutes.to_i}"
      crawl.setCrawlStartingVariables('total_minutes' => crawl.total_minutes.to_i)
      if crawl.crawl_type == 'url_crawl'
        Crawl.save_new_sites(crawl.id, 'processor_name' => processor_name, 'is_do' => true)
      elsif crawl.crawl_type == 'keyword_crawl'
        SaveSitesFromGoogle.start_batch(crawl.id, 'processor_name' => processor_name, 'is_do'=> true)
      end
    end
  end
  
  def setCrawlStartingVariables(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    puts "setting crawl starting variables"
    
    crawl_keys = [
      "#{is_do}crawl/#{self.id}/urls_found",
      "#{is_do}crawl/#{self.id}/processing_batches/ids",
      "#{is_do}crawl/#{self.id}/expired_ids",
      "#{is_do}crawl/#{self.id}/urls_crawled",
      "#{is_do}crawl/#{self.id}/progress",
      "#{is_do}crawl/#{self.id}/expired_domains",
      "#{is_do}crawl/#{self.id}/gathering_batches/total",
      "#{is_do}crawl/#{self.id}/available",
      "#{is_do}crawl/#{self.id}/processing_batches/total",
      "#{is_do}crawl/#{self.id}/start_time",
      "#{is_do}crawl/#{self.id}/processing_batches/running",
      "#{is_do}crawl/#{self.id}/processing_batches/finished",
      "#{is_do}crawl/#{self.id}/checked",
      "#{is_do}crawl/#{self.id}/gathering_batches/running",
      "#{is_do}crawl/#{self.id}/gathering_batches/finished",
      "#{is_do}crawl/#{self.id}/total_minutes_to_run",
      "#{is_do}crawl/#{self.id}/broken_domains",
      "#{is_do}finished_processing/#{self.id}"
  ]
    
    $redis.sadd "#{is_do}all_ids/#{self.id}", crawl_keys
    
    crawls_list = Rails.cache.read(["#{is_do}crawls_list"]).to_a
    new_crawls_list = Rails.cache.write(["#{is_do}crawls_list"], crawls_list.push(self.id))
    
    running_crawls = Rails.cache.read(["#{is_do}running_crawls"]).to_a
    expired_crawls = Rails.cache.read(["#{is_do}expired_rotation"]).to_a
    new_running_crawls = Rails.cache.write(["#{is_do}running_crawls"], running_crawls.push(self.id))
    new_expired_rotation = Rails.cache.write(["#{is_do}expired_rotation"], expired_crawls.push(self.id))
    
    Rails.cache.write(["#{is_do}crawl/#{self.id}/start_time"], Time.now, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/total_minutes_to_run"], options['total_minutes'].to_i, raw: true)
    
    Rails.cache.write(["#{is_do}crawl/#{self.id}/gathering_batches/total"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/gathering_batches/running"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/gathering_batches/finished"], 0, raw: true)

    Rails.cache.write(["#{is_do}crawl/#{self.id}/processing_batches/total"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/processing_batches/running"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/processing_batches/finished"], 0, raw: true)
    
    Rails.cache.write(["#{is_do}crawl/#{self.id}/processing_batches/ids"], [])
    Rails.cache.write(["#{is_do}crawl/#{self.id}/available"], [])
    Rails.cache.write(["#{is_do}crawl/#{self.id}/checked"], [])
    Rails.cache.write(["#{is_do}crawl/#{self.id}/expired_ids"], [])
    
    Rails.cache.write(["#{is_do}crawl/#{self.id}/urls_found"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/urls_crawled"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/expired_domains"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/broken_domains"], 0, raw: true)
    Rails.cache.write(["#{is_do}crawl/#{self.id}/progress"], 0.00, raw: true)

    Rails.cache.write(["#{is_do}current_processing_batch_id"], '')
  end
  
  def self.decision_maker(options={})
    puts "making a decision #{options}"
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    
    processor_name = options['processor_name']
    user = User.using(:main_shard).find(options['user_id'].to_i)
    plan = user.subscription.plan
    emails = ['alex@test.com', 'batman34@gmail.com', 'gregoryortiz@mac.com']
    if emails.include?(user.email)
      puts 'this user is allowed to run unlimted crawls'
      crawls_at_the_same_time = 100
    else
      crawls_at_the_same_time = plan.crawls_at_the_same_time
    end
    
    if user.minutes_used.to_f < 4500.to_f
      
      number_of_pending_crawls = Crawl.using("#{processor_name}").where(status: "pending", user_id: options['user_id'].to_i).count
      number_of_running_crawls = Crawl.using("#{processor_name}").where(status: "running", user_id: options['user_id'].to_i).count
      
      puts "the number of pending crawls is #{number_of_pending_crawls}"
      puts "the number of running crawls is #{number_of_running_crawls}"
      
      if number_of_running_crawls < crawls_at_the_same_time
        if number_of_pending_crawls > 0
          number_of_apps_running = HerokuPlatform.new.app_list.count
          puts "the number of apps running are #{number_of_apps_running}"
          if number_of_apps_running < 99
            puts "decision: starting new crawl with the options #{options}"
            
            list_of_all_crawls = HerokuPlatform.new.app_list.map{|app| app['name']}.select{|obj| obj.include?('revivecrawler')}

            if !$redis.get("#{is_do}list_of_running_crawls").to_s.empty?
              list_of_running_crawls = JSON.parse($redis.get("#{is_do}list_of_running_crawls"))
              names_of_running_crawls = list_of_running_crawls.group_by{|crawl| crawl['name']}.keys
              puts "list of names of the running crawls are #{names_of_running_crawls}" 
              
              available_crawls = ( (list_of_all_crawls | names_of_running_crawls) - names_of_running_crawls ).to_a
              puts "list of available crawls #{available_crawls}"
              
              if !options['crawl_name'].to_s.empty?
                name = options['crawl_name']
                available_crawl_hash = {"name"=>name, "crawl_id"=>options['crawl_id'], "processor_name"=>processor_name}
                updated_list_of_running_crawls = list_of_running_crawls.push(available_crawl_hash)
                puts "the updated list of running crawls is #{updated_list_of_running_crawls}"
                $redis.set("#{is_do}list_of_running_crawls", updated_list_of_running_crawls.to_json)
                #start new crawl based on option
                Api.delay.start_crawl('app_name' => name, 'processor_name' => processor_name, 'crawl_id' => options['crawl_id'])
              elsif available_crawls.empty?
                puts "there are no available crawls adding new crawl to existing crawl"
                crawl_with_least = JSON.parse($redis.get("#{is_do}list_of_running_crawls")).group_by{|crawl| crawl['name']}.sort_by{|k,v| v.count}[0][0]
                puts "the crawl with the least is #{crawl_with_least}"
                available_crawl_hash = {"name"=>crawl_with_least, "crawl_id"=>options['crawl_id'], "processor_name"=>processor_name}
                updated_list_of_running_crawls = list_of_running_crawls.push(available_crawl_hash)
                puts "the updated list of running crawls is #{updated_list_of_running_crawls}"
                $redis.set("#{is_do}list_of_running_crawls", updated_list_of_running_crawls.to_json)
                Api.delay.start_crawl('app_name' => crawl_with_least, 'processor_name' => processor_name, 'crawl_id' => options['crawl_id'])
              else
                name = available_crawls[0]
                available_crawl_hash = {"name"=>name, "crawl_id"=>options['crawl_id'], "processor_name"=>processor_name}
                updated_list_of_running_crawls = list_of_running_crawls.push(available_crawl_hash)
                puts "the updated list of running crawls is #{updated_list_of_running_crawls}"
                $redis.set("#{is_do}list_of_running_crawls", updated_list_of_running_crawls.to_json)
                Api.delay.start_crawl('app_name' => name, 'processor_name' => processor_name, 'crawl_id' => options['crawl_id'])
              end
            
            else
              puts "there is not a list of running crawls saved on redis"
              # HerokuPlatform.start_app('revivecrawler1')
              available_crawl_hash = {"name"=>'revivecrawler1', "crawl_id"=>options['crawl_id'], "processor_name"=>processor_name}
              $redis.set("#{is_do}list_of_running_crawls", [available_crawl_hash].to_json)
              Api.delay.start_crawl('app_name' => name, 'processor_name' => processor_name, 'crawl_id' => options['crawl_id'])
            end
            
          end
        end
      else
        puts 'decision: exceeded crawls that can be performed at the same time'
      end
      
    end
  end
  
  def self.save_new_reverse_crawl(user_id, url, options = {})
    puts "save_new_reverse_crawl: the initial url is #{url}"
    m = MajesticSeo::Api::Client.new(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
    res = GetRefDomains.for_url('url' => url)
    base_urls = res.select{|r| r["cf"].to_i < 30 || r['tf'].to_i < 30}.map{|r| r["url"]}.split(",").flatten
    puts "save_new_reverse_crawl: the base urls are #{base_urls}"
    Crawl.save_new_crawl(user_id, base_urls, options)
  end
  
  def self.save_new_crawl(user_id, base_urls, options = {})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';


    puts "the options for the save_new_crawl are #{options}"
    user = User.using(:main_shard).find(user_id)
    plan = user.subscription.plan
    beta = true
    name = options[:name]
    moz_da = options[:moz_da].nil? ? nil : options[:moz_da].to_i
    majestic_tf = options[:majestic_tf].nil? ? nil : options[:majestic_tf].to_i
    notify_me_after = options[:notify_me_after].nil? ? nil : options[:notify_me_after].to_i
    unless is_do.present?
      total_crawl_minutes = ((options[:hours].to_i*60)+options[:minutes].to_i)
    else
      total_crawl_minutes = 0
    end
    puts "the total crawl minutes are #{total_crawl_minutes}"
    
    
    if beta == true
      if options[:maxpages].nil?
        maxpages = 10
      else
        maxpages = options[:maxpages].to_i > 500 ? 500 : options[:maxpages].to_i
      end
    else
      maxpages = options[:maxpages].empty? ? 10 : options[:maxpages].to_i
    end
    #parsing URL list
    if base_urls.include?("\r\n")
      urls_array = base_urls.split(/[\r\n]+/).map(&:strip).flatten
    else
      urls_array = base_urls.split(",").flatten
    end

    #need to change to local redis instance  for development
    if !Rails.env.development?
      redis_conn = Redis.new(url: 'redis://redistogo:46d4f04e871ae440da550714fdbd5c77@cobia.redistogo.com:9135/')
    else
      redis_conn = Redis.new(url: 'redis://127.0.0.1:6379/')
    end

    if JSON.parse(redis_conn.get("#{is_do}list_of_running_crawls")).to_a.empty?
      processor_name = 'processor'
      puts 'save_new_crawl: there are currently no running crawls saving crawl to processor'
    else
      processors_array = ['processor_three', 'processor_four', 'processor', 'processor_one', 'processor_two']
      new_processors_array = []
      processors_array.each do |p|
        new_processors_array.push({'processor_name' => p, 'running_count' => JSON.parse(redis_conn.get('list_of_running_crawls')).select{|c| c['processor_name'] == p}.count})
      end
      processor_name = new_processors_array.sort_by{|k,v| k['running_count']}[0]['processor_name']
      puts "save_new_crawl: the processor name for the new crawl is #{processor_name}"
    end

    #check do option when save
    new_crawl = Crawl.using("#{processor_name}").create(user_id: user_id, name: name, maxpages: maxpages, crawl_type: 'url_crawl', base_urls: urls_array, total_sites: urls_array.count.to_i, status: 'pending', max_pages_allowed: plan.pages_per_crawl.to_i, moz_da: moz_da, majestic_tf: majestic_tf, notify_me_after: notify_me_after, processor_name: processor_name, total_minutes: total_crawl_minutes, is_do: is_do.present?)
    #get processor and heroku app ID for universal management
    unless is_do.present?
      new_heroku_app_object = HerokuApp.using("#{processor_name}").create(status: "pending", crawl_id: new_crawl.id, verified: 'pending', user_id: user.id, processor_name: processor_name)
      ShardInfo.using(:main_shard).create(user_id: user.id, processor_name: processor_name, crawl_id: new_crawl.id, heroku_app_id: new_heroku_app_object.id)
    else
      ShardInfo.using(:main_shard).create(user_id: user.id, processor_name: processor_name, crawl_id: new_crawl.id)
    end
    UserDashboard.add_pending_crawl(user.user_dashboard.id)
    # Api.delay.process_new_crawl(user_id: user.id, processor_name: processor_name)
    
    Api.delay.process_new_crawl('crawl_id' => new_crawl.id, 'user_id' => user_id, 'processor_name' => processor_name, 'crawl_name' => options[:crawl_name].to_s, 'is_do'=> is_do.present?)
    
    # Crawl.decision_maker('crawl_id' => new_crawl.id, 'user_id' => user_id, 'processor_name' => processor_name)
  end
  
  def self.save_new_keyword_crawl(user_id, keyword, options = {})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    user = User.using(:main_shard).find(user_id)
    plan = user.subscription.plan
    beta = true
    name = options[:name]
    moz_da = options[:moz_da].nil? ? nil : options[:moz_da].to_i
    majestic_tf = options[:majestic_tf].nil? ? nil : options[:majestic_tf].to_i
    notify_me_after = options[:notify_me_after].nil? ? nil : options[:notify_me_after].to_i
    crawl_start_date = options[:crawl_start_date].nil? ? '' : options[:crawl_start_date]
    crawl_end_date = options[:crawl_end_date].nil? ? '' : options[:crawl_end_date]
    total_crawl_minutes = ((options[:hours].to_i*60)+options[:minutes].to_i)
    puts "the total crawl minutes are #{total_crawl_minutes}"
    
    if beta == true
      if options[:maxpages].nil?
        maxpages = 10
      else
        maxpages = options[:maxpages].to_i > 500 ? 500 : options[:maxpages].to_i
      end
    else
      maxpages = options[:maxpages].empty? ? 10 : options[:maxpages].to_i
    end

    redis_conn = Redis.new(url: 'redis://redistogo:46d4f04e871ae440da550714fdbd5c77@cobia.redistogo.com:9135/')
    if JSON.parse(redis_conn.get("#{is_do}list_of_running_crawls")).to_a.empty?
      processor_name = 'processor'
      puts 'save_new_keyword_crawl: there are currently no running crawls saving crawl to processor'
    else
      processors_array = ['processor_three', 'processor_four', 'processor', 'processor_one', 'processor_two']
      new_processors_array = []
      processors_array.each do |p|
        new_processors_array.push({'processor_name' => p, 'running_count' => JSON.parse(redis_conn.get('list_of_running_crawls')).select{|c| c['processor_name'] == p}.count})
      end
      processor_name = new_processors_array.sort_by{|k,v| k['running_count']}[0]['processor_name']
      puts "save_new_keyword_crawl: the processor name for the new crawl is #{processor_name}"
    end
    
    new_crawl = Crawl.using("#{processor_name}").create(user_id: user_id, name: name, maxpages: maxpages, crawl_type: 'keyword_crawl', base_keyword: keyword, status: 'pending', crawl_start_date: crawl_start_date, crawl_end_date: crawl_end_date, max_pages_allowed: plan.pages_per_crawl.to_i, moz_da: moz_da, majestic_tf: majestic_tf, notify_me_after: notify_me_after, iteration: 0, processor_name: processor_name, total_minutes: total_crawl_minutes)
    new_heroku_app_object = HerokuApp.using("#{processor_name}").create(status: "pending", crawl_id: new_crawl.id, verified: 'pending', user_id: user_id, processor_name: processor_name)
    ShardInfo.using(:main_shard).create(user_id: user.id, processor_name: processor_name, crawl_id: new_crawl.id, heroku_app_id: new_heroku_app_object.id)
    UserDashboard.add_pending_crawl(user.user_dashboard.id)
    
    Api.delay.process_new_crawl('crawl_id' => new_crawl.id, 'user_id' => user_id, 'processor_name' => processor_name, 'crawl_name' => options[:crawl_name])
  end
  
  def self.save_new_sites(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    processor_name = options['processor_name']
    crawl = Crawl.using("#{processor_name}").find(crawl_id)
    
    crawl.base_urls.each do |u|
      new_site = Site.using("#{processor_name}").create(base_url: u.to_s, maxpages: crawl.maxpages.to_i, crawl_id: crawl_id, processing_status: "pending")
      new_site.create_gather_links_batch(status: "pending")
      site_id = new_site.id
      $redis.sadd "#{is_do}all_ids/#{crawl_id}", ["#{is_do}site/#{new_site.id}/processing_batches/total", "#{is_do}site/#{site_id}/broken_domains", "#{is_do}site/#{site_id}/processing_batches/finished", "#{is_do}site/#{site_id}/expired_domains", "#{is_do}site/#{site_id}/processing_batches/running", "#{is_do}site/#{site_id}/total_site_urls"]
    end
    
    crawl.update(status: 'running')
    GatherLinks.delay.start('crawl_id' => crawl.id, 'processor_name' => processor_name)
    # HerokuApp.using("#{processor_name}").update(crawl.heroku_app.id, status: 'running')

  end
  
  def self.update_all_crawl_stats(user_id)
    user = User.find(user_id)
    crawls = user.crawls.select('id')
    crawls.each do |c|
      Crawl.update_stats(c.id)
    end
  end
  
  # def self.update_stats(crawl_id)
  #   crawl = Crawl.find(crawl_id)
  #   total_expired = crawl.pages.where(available: 'true').count
  #   Crawl.update(crawl.id, total_expired: total_expired.to_i)
  # end
  
  
  def self.crawl_stats(broken, available)
    # crawl = Crawl.using(:processor).find(crawl_id)
    # broken = crawl.total_broken.to_i
    # available = crawl.total_expired.to_i
    
    LazyHighCharts::HighChart.new('graph') do |f|
      #f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
      f.xAxis(:categories => ["Broken", "Available"])
      f.series(:showInLegend => false , :data => [broken, available])
      #f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])

      f.yAxis [
        {:title => {:text => ""} }
      ]

      #f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"bar", backgroundColor: "#fff"})
    end
  end


  def self.site_stats(site_id)
    site = Site.find(site_id)
    internal = site.pages.where(internal: true).uniq.count
    external = site.pages.where(internal: false).uniq.count
    broken = site.pages.where(status_code: '404').uniq.count
    available = site.pages.where(status_code: '0', internal: false).uniq.count

    LazyHighCharts::HighChart.new('graph') do |f|
      #f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
      f.xAxis(:categories => ["Internal", "External", "Broken", "Available"])
      f.series(:showInLegend => false , :data => [internal, external, broken, available])
      #f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])

      f.yAxis [
        {:title => {:text => ""} }
      ]

      #f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
      f.chart({:defaultSeriesType=>"bar", backgroundColor: "#F4F4F2"})
    end
  end
  
  def cache_available_sites
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    cache = Rails.cache.read(["#{is_do}crawl/#{self.id}/available/#{self.processor_name}"])
    
    if cache.nil?
      puts "setting available sites cache for the crawl #{self.id}"
      return Page.using("#{self.processor_name}").where(crawl_id: self.id, available: 'true')
    else
      puts "gettin available sites from cache for crawl #{self.id}"
      return cache
    end
  end
  
  def self.save_all_available_sites
    user_ids_array = Subscription.using(:main_shard).where(status: 'active').map(&:user_id)
    user_ids_array.each do |user_id|
      puts "the user id is #{user_id}"
      processors_array = ['processor', 'processor_one', 'processor_two', 'processor_three', 'processor_four']
      processors_array.each do |processor|
        puts "saving new available sites"
        Crawl.using("#{processor}").where(user_id: user_id.to_i).each{|c| c.save_available_sites}
      end
    end
  end
  
  def save_available_sites(options={})
    self.available_sites = Page.using("#{self.processor_name}").where(available: 'true', crawl_id: self.id).pluck(:id, :simple_url, :da, :pa, :trustflow, :citationflow, :refdomains, :backlinks)
    self.save!
    return self.available_sites
  end
  
  def available_to_csv
    attributes = %w[simple_url da pa trustflow citationflow refdomains backlinks]
    CSV.generate(headers: true) do |csv|
      csv << attributes
      self.available_sites.each do |page|
        csv << [page[1], page[2], page[3], page[4], page[5], page[6], page[7]]
      end
    end
  end
  
  def self.delete_all_crawls
    apps = HerokuPlatform.new.app_list
    apps.each do |app|
      if app['name'].include?('revivecrawler')
        begin
          puts "delete_all_crawls: deleting crawl #{app['name']}"
          HerokuPlatform.new.delete_app(app['name'])
        rescue
          puts "delete_all_crawls: failed to delete crawl #{app['name']}"
        end
      end
    end
  end
  
  def self.get_available_domains(options={})
    available_domains = Rails.cache.read(["user/#{options['user_id']}/available_domains"]).to_a
    if available_domains.empty?
      return Crawl.save_available_domains('user_id' => options['user_id'])
    else
      return available_domains.map{|crawl| crawl['expired_domains']}.flatten(1)
    end
  end
  
  def self.save_available_domains(options={})
    processor_names_array = ["processor", "processor_one", "processor_two", "processor_three", "processor_four"]
    crawls_array = []
    processor_names_array.each do |processor|
      Crawl.using("#{processor}").where(user_id: options['user_id'].to_i, status: 'finished').each do |crawl|
        crawls_array << {'crawl_id' => crawl.id, 'expired_count' => crawl.total_expired, 'expired_domains' => crawl.available_sites}
      end
    end
    Rails.cache.write(["user/#{options['user_id']}/available_domains"], crawls_array)
    return crawls_array.map{|crawl| crawl['expired_domains']}.flatten(1)
  end
  
  def self.delete_and_stop_all_apps
    JSON.parse($redis.get('list_of_running_crawls')).each do |crawl|
      puts "shutting down crawl #{crawl['crawl_id']}"
      Crawl.shut_down('crawl_id' => crawl['crawl_id'], 'processor_name' => crawl['processor_name'])
    end
    Crawl.delete_all_crawls
    $redis.set('list_of_running_crawls', [].to_json)
    $redis.set('redis_urls', {}.to_json)
    $redis.set('deleted_crawls', [].to_json)
    puts "done deleting crawls and stoping them"
  end
  
  def self.delete_and_stop_app(app_number)
    puts "shutting down app revivecrawler#{app_number}"
    crawls = JSON.parse($redis.get('list_of_running_crawls')).select{|crawl| crawl['name']=="revivecrawler#{app_number}"}
    crawls.each do |crawl|
      puts "shutting down crawl #{crawl['crawl_id']}"
      Crawl.shut_down('crawl_id' => crawl['crawl_id'], 'processor_name' => crawl['processor_name'])
    end
    Crawl.delete_app(app_number)
    $redis.set('list_of_running_crawls', JSON.parse($redis.get('list_of_running_crawls')).reject{|crawl| crawl['name']=="revivecrawler#{app_number}"}.to_json)
    puts "done deleting app revivecrawler#{app_number} and stopping all the corresponding crawls"
  end

  def self.do_delete_and_stop_all_apps
    JSON.parse($redis.get('do_list_of_running_crawls')).each do |crawl|
      puts "shutting down crawl #{crawl['crawl_id']}"
      Crawl.shut_down('crawl_id' => crawl['crawl_id'], 'processor_name' => crawl['processor_name'])
    end
    Crawl.delete_all_crawls
    $redis.set('do_list_of_running_crawls', [].to_json)
    $redis.set('do_redis_urls', {}.to_json)
    $redis.set('do_deleted_crawls', [].to_json)
    puts "done deleting crawls and stoping them"
  end

  def self.do_delete_and_stop_app(app_number)
    puts "shutting down app revivecrawler#{app_number}"
    crawls = JSON.parse($redis.get('list_of_running_crawls')).select{|crawl| crawl['name']=="revivecrawler#{app_number}"}
    crawls.each do |crawl|
      puts "shutting down crawl #{crawl['crawl_id']}"
      Crawl.shut_down('crawl_id' => crawl['crawl_id'], 'processor_name' => crawl['processor_name'])
    end
    Crawl.delete_app(app_number)
    $redis.set('do_list_of_running_crawls', JSON.parse($redis.get('list_of_running_crawls')).reject{|crawl| crawl['name']=="revivecrawler#{app_number}"}.to_json)
    puts "done deleting app revivecrawler#{app_number} and stopping all the corresponding crawls"
  end

  
  def self.new_apps(number_of_apps)
    a=*(1..number_of_apps.to_i)
    a.each do |app_number|
      Crawl.new_app(app_number)
    end
  end
  
  def self.new_range_of_apps(start_of_range, end_of_range)
    a=*(start_of_range.to_i..end_of_range.to_i)
    a.each do |app_number|
      Crawl.new_app(app_number)
    end
  end
  
  def self.new_app(app_number)
    HerokuPlatform.create_new_app('reviveprocessor', "revivecrawler#{app_number}")
  end
  
  def self.delete_app(app_number)
    HerokuPlatform.new.delete_app("revivecrawler#{app_number}")
  end

  def self.do_new_app(app_number)
    HerokuPlatform.create_new_app('reviveprocessor', "revivecrawler#{app_number}")
    #Droplet delete app number
  end

  def self.do_delete_app(app_number)
    HerokuPlatform.new.delete_app("revivecrawler#{app_number}")
    #Droplet delete app number
  end
  
  def self.running_list(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    JSON.parse($redis.get("#{is_do}list_of_running_crawls"))
  end
  
  def self.get_redis_memory_for(app_number)
    redis_url = JSON.parse($redis.get('redis_urls')).select{|c| c["revivecrawler#{app_number}"]}["revivecrawler#{app_number}"]
    begin
      redis = Redis.new(url: redis_url)
      redis_mem = redis.info['used_memory_human'].chomp('M')
      puts "revivecrawler#{app_number} current redis memory is #{redis_mem}"
      return redis_mem
    rescue
      return 404
    end
  end
  
  def self.get_all_redis_memory
    redis_urls = JSON.parse($redis.get('redis_urls'))
    redis_mem_hash = {}
    redis_urls.each do |k,v|
      puts "getting redis mem for #{k} with url #{v}"
      begin
        redis = Redis.new(url: v)
        redis_mem = redis.info['used_memory_human'].chomp('M').to_f
        redis_mem_hash["#{k}"] = redis_mem
        puts "#{k} current redis memory is #{redis_mem}"
      rescue
        nil
      end
    end
    return redis_mem_hash
  end
  
  def self.get_redis_keys_for(crawl_id, sender='crawler', options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    if sender == 'crawler'
      if $redis.keys.include?("#{is_do}all_ids/#{crawl_id}")
        keys = $redis.smembers("#{is_do}all_ids/#{crawl_id}")
      else
        keys = []
      end
    else
      redis_db_connection = Crawl.connect_to_crawler_redis_db(crawl_id)
      if !redis_db_connection.nil?
        if redis_db_connection.keys.include?("#{is_do}all_ids/#{crawl_id}")
          keys = redis_db_connection.smembers("#{is_do}all_ids/#{crawl_id}")
        else
          keys = []
        end
      else
        keys = []
      end
    end
    return keys
  end
  
  def self.delete_redis_keys_for(crawl_id, sender='crawler', options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    keys = Crawl.get_redis_keys_for(crawl_id, sender).to_a
    puts "the keys count is #{keys.count}"
    if !keys.empty?
      if sender == 'crawler'
        $redis.del(keys)
        
        expired_ids = $redis.smembers("#{is_do}all_expired_ids").select{|obj| obj.include?("expired-#{crawl_id}")}
        if expired_ids.count > 0
          $redis.del(expired_ids)
          $redis.srem("#{is_do}all_expired_ids", expired_ids)
        end
        
        processing_ids = $redis.smembers("#{is_do}all_processing_ids").select{|obj| obj.include?("process-#{crawl_id}")}
        if processing_ids.count > 0
          $redis.del(processing_ids)
          $redis.srem("#{is_do}all_processing_ids", processing_ids)
        end
        $redis.del("#{is_do}all_ids/#{crawl_id}")
      else
        begin
          redis_db_connection = Crawl.connect_to_crawler_redis_db(crawl_id)
          redis_db_connection.del(keys)
          expired_ids = redis_db_connection.smembers("#{is_do}all_expired_ids").select{|obj| obj.include?("expired-#{crawl_id}")}
          if expired_ids.count > 0
            redis_db_connection.del(expired_ids)
            redis_db_connection.srem("#{is_do}all_expired_ids", expired_ids)
          end
          processing_ids = redis_db_connection.smembers("#{is_do}all_processing_ids").select{|obj| obj.include?("process-#{crawl_id}")}
          if processing_ids.count > 0
            redis_db_connection.del(processing_ids)  
            redis_db_connection.srem("#{is_do}all_processing_ids", processing_ids)
          end
          redis_db_connection.del("#{is_do}all_ids/#{crawl_id}")
        rescue
          nil
        end
      end
    else
      puts "deleted all redis keys for #{crawl_id}"
    end
  end
  
  def self.all_processing_stats
    crawl_ids = Crawl.running_list.map{|c|c["crawl_id"]}
    crawl_ids.each do |id|
      begin
        Crawl.running_count_for(id, sender='processor')
      rescue
        nil
      end
    end
  end
  
  def self.running_count_for(crawl_id, sender='crawler', options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    if sender == 'crawler'
      expired_count = $redis.smembers("#{is_do}all_expired_ids").select{|objs| objs.include?("expired-#{crawl_id}")}.count
      processing_count = $redis.smembers("#{is_do}all_processing_ids").select{|obj| obj.include?("process-#{crawl_id}")}.count
    else
      redis_db_connection = Crawl.connect_to_crawler_redis_db(crawl_id)
      if !redis_db_connection.nil?
        processing_count = redis_db_connection.smembers("#{is_do}all_processing_ids").select{|obj| obj.include?("process-#{crawl_id}")}.count
        expired_count = redis_db_connection.smembers("#{is_do}all_expired_ids").select{|objs| objs.include?("expired-#{crawl_id}")}.count
      else
        processing_count = 0
        processing_count = 0
      end
    end
    puts "the number of processing batches left are #{processing_count} and the number of expired domains left to be processed are #{expired_count} for the crawl #{crawl_id}"
    return {"processing_count" => processing_count, "expired_count" => expired_count, 'crawl_id' => crawl_id}
  end
  
  def self.get_stats(crawl_id, sender='crawler', options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    crawl_urls_found = "#{is_do}crawl/#{crawl_id}/urls_found"
    crawl_expired_domains = "#{is_do}crawl/#{crawl_id}/expired_domains"
    crawl_broken_domains = "#{is_do}crawl/#{crawl_id}/broken_domains"
    
    if sender == 'crawler'
      stats = Rails.cache.read_multi(crawl_urls_found, crawl_expired_domains, crawl_broken_domains, raw: true)
      crawl_stats = {'total_urls_found' => stats[crawl_urls_found].to_i, 'total_broken' => stats[crawl_broken_domains].to_i, 'total_expired' => stats[crawl_expired_domains].to_i}
    else
      begin
        redis_cache_connection = Crawl.connect_to_crawler_redis_cache(crawl_id)
        if !redis_cache_connection.nil?
          stats = redis_cache_connection.read_multi(crawl_urls_found, crawl_expired_domains, crawl_broken_domains, raw: true)
          crawl_stats = {'total_urls_found' => stats[crawl_urls_found].to_i, 'total_broken' => stats[crawl_broken_domains].to_i, 'total_expired' => stats[crawl_expired_domains].to_i}
        else
          crawl_stats = {'total_urls_found' => 0, 'total_broken' => 0, 'total_expired' => 0}
        end
      rescue
        crawl_stats = {'total_urls_found' => 0, 'total_broken' => 0, 'total_expired' => 0}
      end
    end
    
    puts "the crawl stats are #{crawl_stats}"
    return crawl_stats
  end
  
  def self.update_stats(crawl_id, processor_name, sender='crawler')
    stats = Crawl.get_stats(crawl_id, sender)
    puts "SidekiqStats: updating crawl stats for crawl #{crawl_id}"
    crawl = Crawl.using("#{processor_name}").where(id: crawl_id.to_i).first
    if crawl && crawl.status != 'finished'
      crawl.update_attributes(stats.reject{|k,v|v==0})
    end
  end
  
  def self.connect_to_crawler_redis_cache(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    crawl_obj = JSON.parse($redis.get("#{is_do}list_of_running_crawls")).select{|c|c['crawl_id']==crawl_id.to_i}
    puts "the crawl obj is #{crawl_obj} redis cache"
    if !crawl_obj.empty?
      app_name = crawl_obj[0]['name']
      puts "the crawl app name is #{app_name}"
      redis_url = JSON.parse($redis.get('redis_urls'))["#{app_name}"]
      if !redis_url.to_s.empty?
        puts "the redis url is #{redis_url}"
        redis_cache_connection = ActiveSupport::Cache.lookup_store(:redis_store, redis_url)
      else
        new_redis_url = Crawl.add_redis_url_for(app_name)
        puts "the new redis url is #{new_redis_url}"
        redis_cache_connection = ActiveSupport::Cache.lookup_store(:redis_store, new_redis_url)
      end
      return redis_cache_connection
    end
  end
  
  def self.connect_to_crawler_redis_db(crawl_id)
    crawl_obj = Crawl.get('crawl_id', crawl_id.to_i)[0]
    puts "the crawl obj is #{crawl_obj} redis db"
    if !crawl_obj.nil?
      app_name = crawl_obj['name']
      redis_url = JSON.parse($redis.get('redis_urls'))["#{app_name}"]
      puts "the redis url is #{redis_url}"
      redis_db_connection = Redis.new(:url => redis_url)
      return redis_db_connection
    else
      puts "checking deleted crawls"
      crawl_has_been_deleted = Crawl.get('crawl_id', crawl_id.to_i, 'finished')[0]
      if !crawl_has_been_deleted.nil?
        app_name = crawl_has_been_deleted['name']
        redis_url = JSON.parse($redis.get('redis_urls'))["#{app_name}"]
        puts "the redis url is #{redis_url}"
        redis_db_connection = Redis.new(:url => redis_url)
        return redis_db_connection
      end
    end
  end
  
  def self.time_running(crawl_id)
    crawl_total_time_in_minutes = (Time.now - Chronic.parse(Rails.cache.read(["crawl/#{crawl.id}/start_time"], raw: true))).to_f/60.to_f
    user = User.using(:main_shard).find(app.user_id)
    user.update(minutes_used: user.minutes_used.to_f+crawl_total_time_in_minutes)
  end
  
  def self.remove_from_list_of_running(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    list_of_running_crawls = JSON.parse($redis.get("#{is_do}list_of_running_crawls"))
    if !list_of_running_crawls.nil?
      $redis.set("#{is_do}list_of_running_crawls", JSON.parse($redis.get("#{is_do}list_of_running_crawls")).reject{|crawl| crawl['crawl_id']==crawl_id.to_i}.to_json)
    end
    puts "removed crawl #{crawl_id} from list of running"
  end
  
  def self.remove_from_crawler_list_of_running(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    redis_cache_connection = Crawl.connect_to_crawler_redis_cache(crawl_id)
    begin
      if !redis_cache_connection.nil?
        crawler_running_crawls = redis_cache_connection.read(["#{is_do}running_crawls"]).to_a
        crawler_expired_crawls = redis_cache_connection.read(["#{is_do}expired_rotation"]).to_a
        redis_cache_connection.write(["#{is_do}running_crawls"], crawler_running_crawls-[crawl_id])
        redis_cache_connection.write(["#{is_do}expired_rotation"], crawler_expired_crawls-[crawl_id])
        puts "removed crawl #{crawl_id} from list of running"
      end
    rescue
      nil
    end
  end
  
  def self.update_status_to_finish(crawl_id, processor_name, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    crawl = Crawl.using("#{processor_name}").where(id: crawl_id.to_i).first
    puts "here is the crawl to stop #{crawl_id} on the processor #{processor_name}"
    if crawl
      unless is_do
        heroku_app = crawl.heroku_app
        crawl.update(status: 'finished')
        puts "shut_down: updated crawl #{crawl.id} new status #{crawl.status}"
        if heroku_app
          heroku_app.update(status: 'finished')
          puts "shut_down: updated heroku app #{heroku_app.id} new status #{heroku_app.status}"
        end
      else
        #droplet update status
        crawl.update(status: 'finished')
        puts "shut_down: updated crawl #{crawl.id} new status #{crawl.status}"
        droplet = crawl.droplet
        if droplet
          droplet.update(status: 'finished')
          puts "shut_down: updated droplet app #{droplet.id} new status #{droplet.status}"
        end
      end

    end
  end
  #set redis URL for heroku  or droplet
  def self.add_redis_url_for(app_name)
    heroku = HerokuPlatform.new
    redis_url = heroku.get_env_vars_for(app_name, ['REDISCLOUD_URL'])['REDISCLOUD_URL']
    redis_urls = JSON.parse($redis.get('redis_urls'))
    redis_urls["#{app_name}"] = redis_url
    $redis.set('redis_urls', redis_urls.to_json)
    puts "the redis url is #{redis_url}"
    return redis_url
  end
  
  def self.finished_list(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : ''
    deleted_crawls = JSON.parse($redis.get("#{is_do}deleted_crawls"))
    return deleted_crawls
  end
  
  def self.get_deleted_crawl(crawl_id)
    deleted_crawl = Crawl.get('crawl_id', crawl_id.to_i, 'finished')[0]
    if !deleted_crawl.nil?
      name = deleted_crawl['name']
    else
      name = []
    end
    return name
  end
  
  def self.add_to_deleted_crawls(crawl_id, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';

    crawl_obj = JSON.parse($redis.get("#{is_do}list_of_running_crawls")).select{|c|c['crawl_id']==crawl_id.to_i}
    if !crawl_obj.empty?
      app_name = crawl_obj[0]['name']
      redis_url = JSON.parse($redis.get('redis_urls'))["#{app_name}"]
      if !$redis.get("#{is_do}deleted_crawls").nil?
        deleted_crawls = JSON.parse($redis.get("#{is_do}deleted_crawls"))
        crawl_obj[0]["redis_url"] = redis_url
        new_deleted_crawl = deleted_crawls.push(crawl_obj[0])
        $redis.set("#{is_do}deleted_crawls", new_deleted_crawl.to_json)
      else
        crawl_obj[0]["redis_url"] = redis_url
        new_deleted_crawl = crawl_obj[0]
        $redis.set("#{is_do}deleted_crawls", [new_deleted_crawl].to_json)
      end
    end
  end
  
  def self.all_app_names
    app_names = HerokuPlatform.new.app_list.map{|app| app['name']}.select{|obj| obj.include?('revivecrawler')}
    return app_names
  end
  #droplet all app names
  def self.all_app_names
    app_names = HerokuPlatform.new.app_list.map{|app| app['name']}.select{|obj| obj.include?('revivecrawler')}
    return app_names
  end
  
  def self.running_grouped_by_app_name(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    grouped_by_app_name = JSON.parse($redis.get("#{is_do}list_of_running_crawls")).group_by{|crawl| crawl['name']}
    return grouped_by_app_name
  end
  
  def self.available_apps
    list_of_all_crawls = Crawl.all_app_names
    list_of_running_crawls = Crawl.running_list
    names_of_running_crawls = list_of_running_crawls.group_by{|crawl| crawl['name']}.keys
    puts "list of names of the running crawls are #{names_of_running_crawls}" 
    available_crawls = ( (list_of_all_crawls | names_of_running_crawls) - names_of_running_crawls ).to_a
    return available_crawls
  end
  #app status should reflect both heroku and droplet
  def self.app_stats
    all_apps = []
    available_apps = Crawl.available_apps
    running_apps = Crawl.running_grouped_by_app_name
    running_apps.each do |k,v|
      app = "#{k}"
      app_number = app.sub('revivecrawler', '')
      mem = Crawl.get_redis_memory_for(app_number)
      stat = {'app_name' => "#{k}", 'count' => v.count, 'mem' => mem}
      all_apps.push(stat)
    end
    available_apps.each do |k|
      stat = {'app_name' => "#{k}", 'count' => 0, 'mem' => 0}
      all_apps.push(stat)
    end
    return all_apps
  end
  
  def self.get_all_redis_urls
    app_names = Crawl.all_app_names
    heroku = HerokuPlatform.new
    redis_urls = {}
    app_names.each do |name|
      redis_url = heroku.get_redis_variables_for("#{name}")[:redis_url]
      redis_urls["#{name}"] = redis_url
    end
    return redis_urls
  end
  
  def self.save_all_redis_urls
    redis_urls = Crawl.get_all_redis_urls
    $redis.set('redis_urls', redis_urls.to_json)
    puts "saved all redis urls"
  end
  
  def self.app_count_for(app_name)
    app_stats = Crawl.app_stats
    app_count = app_stats.select{|app| app['app_name'] == "#{app_name}"}[0]['count'].to_i
    return app_count
  end
  
  def self.stop_all_available_apps
    available_apps = Crawl.available_apps
    available_apps.each do |app_name|
      puts "stopping #{app_name}"
      HerokuPlatform.stop_app(app_name)
    end
  end

  def self.get(k,v, list='running')
    if list == 'running'
      crawl = Crawl.running_list.select{|crawl|crawl["#{k}"]==v}
    elsif list == 'finished'
      crawl = Crawl.finished_list.select{|crawl|crawl["#{k}"]==v}
    end

    return crawl
  end

  def self.delete_expired_redis_keys(crawl_id, processor_name, options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : ''
    SidekiqStats.perform_in(10.minutes, crawl_id, processor_name)
    all_items = $redis.smembers("#{is_do}all_ids/#{crawl_id}").select{|i|i.include?('process-')}.to_a
    processing_ids = Rails.cache.read(["#{is_do}crawl/#{crawl_id}/processing_batches/ids"]).to_a
    keys_to_delete = (all_items-processing_ids).to_a
    if !keys_to_delete.empty?
      puts "total keys to delete are #{keys_to_delete.count}"
      $redis.del(keys_to_delete)
    end
  end

  def self.shut_down(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : ''

    puts "starting to shut down crawl #{options['crawl_id']}"
    running_crawls = Crawl.get('crawl_id', options['crawl_id'].to_i)
    if !running_crawls.empty?
      
      puts "getting app count"
      app_name = running_crawls[0]['name']
      app_count = Crawl.app_count_for(app_name)
      puts "getting the crawl stats"
      stats = Crawl.get_stats(options['crawl_id'].to_i, sender='processor').reject{|k,v|v.to_i==0}
      puts "the crawl stats are #{stats}"
      puts "deleting from crawler list of running crawls"
      Crawl.remove_from_crawler_list_of_running(options['crawl_id'].to_i)
      puts "updating status to finish"
      Crawl.update_status_to_finish(options['crawl_id'].to_i, options['processor_name'])
      puts "migrating crawl to deleted crawls hash"
      Crawl.add_to_deleted_crawls(options['crawl_id'])
      crawl = Crawl.using("#{options['processor_name']}").where(id: options['crawl_id'].to_i).first
      if crawl
        puts "updating crawl stats"
        crawl.update(stats)
      end
      # puts "deleting redis keys"
      # Crawl.delete_redis_keys_for(options['crawl_id'].to_i, 'processor')
      if app_count == 1
        puts "stopping crawl dynos"
        unless is_do
          HerokuPlatform.stop_app(app_name)
        else
          #droplet platform sto app
        end

      end
      puts "deleting from list of running crawls"
      Crawl.remove_from_list_of_running(options['crawl_id'].to_i)
      puts "shut down crawl successfully #{options['crawl_id']}"
    else
      
      crawl = Crawl.using("#{options['processor_name']}").where(id: options['crawl_id'].to_i).first
      if crawl && crawl.status != 'finished'
        puts "updating status to finish crawl was not running"
        Crawl.update_status_to_finish(options['crawl_id'].to_i, options['processor_name'])
      end
      puts "shut down crawl successfully #{options['crawl_id']}"
      
    end
  end
  
end
