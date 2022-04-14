class SaveSitesFromGoogle
  
  include Sidekiq::Worker
  sidekiq_options :retry => 3
  
  def perform(crawl_id, options = {})
    if Rails.cache.read(['running_crawls']).to_a.include?(crawl_id)
      puts 'SaveSitesFromGoogle: crawl is still running'
      
      processor_name = options['processor_name']
      crawl = Crawl.using("#{processor_name}").find(crawl_id)
      query = crawl.base_keyword
      param = Crawl::GOOGLE_PARAMS[options['iteration'].to_i]
    
      if crawl.crawl_start_date.nil? && crawl.crawl_end_date.nil?
        puts "the google query is #{link}"
        link = "https://www.google.com/search?q=#{query}+#{param}&rlz=1C5CHFA_enUS561US561&oq=#{query}+#{param}&aqs=chrome..69i57.780j0j1&sourceid=chrome&es_sm=119&ie=UTF-8"
        uri = URI.parse(URI.encode(link))
      else
        puts "the timed google query is #{link}"
        link = "https://www.google.com/search?q=#{query}+#{param}&rlz=1C5CHFA_enUS561US561&es_sm=119&source=lnt&tbs=cdr%3A1%2Ccd_min%3A#{crawl.crawl_start_date}%2Ccd_max%3A#{crawl.crawl_end_date}&tbm="
        uri = URI.parse(URI.encode(link))
      end
    
      page = Nokogiri::HTML(open(uri))
      urls_array = []
      page.css('h3.r').map do |link|
        url = link.children[0].attributes['href'].value
        if url.include?('url?q')
          split_url = url.split("=")[1]
          if split_url.include?('&')
            remove_and_from_url = split_url.split("&")[0]
            urls_array << remove_and_from_url
          end
        end
      end
      
      crawl_status = crawl.status.to_s == 'finished' ? 'finished' : 'running'
    
      crawl.update(total_sites: crawl.total_sites.to_i+urls_array.count.to_i, status: crawl_status)
      urls_array.each do |u|
        puts "the gather links batch of keyword crawl #{u}"
        url = Domainatrix.parse(u.to_s)
        parsed_url = 'www.' + url.domain + "." + url.public_suffix
        site = Site.using("#{processor_name}").create(domain: parsed_url, base_url: u.to_s, maxpages: crawl.maxpages.to_i, crawl_id: crawl_id, processing_status: "pending")
        GatherLinksBatch.using("#{processor_name}").create(site_id: site.id, status: "pending")
        site_id = site.id
        $redis.sadd "all_ids/#{crawl_id}", ["site/#{site_id}/processing_batches/total", "site/#{site_id}/broken_domains", "site/#{site_id}/processing_batches/finished", "site/#{site_id}/expired_domains", "site/#{site_id}/processing_batches/running", "site/#{site_id}/total_site_urls"]
      end
    else
      puts 'SaveSitesFromGoogle: crawl has stopped running and not updating or iterating over'
    end
  end
  
  def on_complete(status, options)
    puts "finished saving sites from google for the crawl #{options['crawl_id']}"
    GatherLinks.start('crawl_id' => options['crawl_id'], 'processor_name' => options['processor_name'])
  end
  
  def self.start_batch(crawl_id, options={})
    processor_name = options['processor_name']
    google_links_batch = Sidekiq::Batch.new
    puts "the crawl id for this google batch is #{crawl_id}"
    iteration = options['iteration'].nil? ? 0 : options['iteration']
    google_links_batch.on(:complete, self, 'bid' => google_links_batch.bid, 'crawl_id' => crawl_id, 'processor_name' => processor_name)
    google_links_batch.jobs do
      begin
        SaveSitesFromGoogle.perform_async(crawl_id, 'iteration' => iteration, 'processor_name' => processor_name)
      rescue
        puts 'failed to save'
      end
    end
  end
  
end