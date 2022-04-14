#require "polipus"

class Scrape
  
  def self.sites(base_urls)
    
    new_crawl = Crawl.create
    
    if base_urls.include?("\r\n")
      urls_array = base_urls.split(/[\r\n]+/).map(&:strip)
    else
      urls_array = base_urls.split(",")
    end
    
    urls_array.each do |u|
      new_site = new_crawl.sites.create(base_url: u.to_s)
      Scrape.start(new_site.id)
    end
    
  end
  
  def self.start(site_id)
    
    site = Site.find(site_id)
    
    options_hash = {
      valid_mime_types: ['text/html'],
      follow_redirects: true, 
      crawl_linked_external: true, 
      redirect_limit: 1, 
      thread_count: 4,
      processing_queue: "CrawlerWorker",
      queue_system: :sidekiq,
      use_encoding_safe_process_job: true,
      crawl_id: "#{site.crawl_id}-#{site.id}",
      direct_call_process_job: true
    }
    
    crawler = Cobweb.new(options_hash)
    crawler.start("#{site.base_url}")
    
    # crawler = CobwebCrawler.new(options_hash)
    # crawler.crawl("#{url}") do |page|
    #   #puts "Just crawled #{page[:url]} and got a status of #{page[:status_code]}."
    #   puts "the self object is #{page[:myoptions][:crawl_id]}"
    #   #puts "the page is #{page}"
    # end
    
  end
  
  # def self.cobweb
  #   options_hash = {
  #     valid_mime_types: ['text/html'],
  #     crawl_linked_external: true,
  #     redirect_limit: 1,
  #     thread_count: 10,
  #     debug: true,
  #     processing_queue: "CrawlerWorker",
  #     crawl_finished_queue: "CrawlerWorker",
  #     queue_system: :sidekiq
  #   }
  #
  #   CobwebCrawler.new(options_hash).crawl("http://railscasts.com/") do |page|
  #     CrawlerWorker.perform_async(page)
  #   end
  #   #crawler.start('http://railscasts.com/')
  #   #puts "start Sidekiq"
  # end
  
  def self.test
    uri = URI.parse(URI.encode("https://www.google.com/search?num=100&rlz=1C5CHFA_enUS561US561&es_sm=119&q=weight+protein+intitle:links&spell=1&sa=X&ei=mx7SVKn0IoboUtrdgsAL&ved=0CBwQvwUoAA&biw=1280&bih=701"))
    page = Nokogiri::HTML(open(uri))   
    page.css('h3.r').map do |link|
      url = link.children[0].attributes['href'].value
      if url.include?('url?q')
        split_url = url.split("=")[1]
        if split_url.include?('&')
          remove_and_from_url = split_url.split("&")[0]
        end
      end
    end
  end
  
  private
  
  def self.print_statistics(statistics)
    puts ""
    puts "Crawl Statistcs"
    puts "==============="
    statistics.keys.each do |key|
      puts "#{key.to_s.ljust(25)}: #{statistics[key]}"
    end
    
    puts ""
    puts "Crawl Finished"
    puts "=============="
  end
  
  # def self.crawl(urls = [], depth = 0, external = false)
  #   starting_urls = urls
  #   hrefs = []
  #
  #   Polipus.crawler('htj', starting_urls, depth_limit: depth) do |crawler|
  #     crawler.skip_links_like(/hhttp[\S]+/)
  #     begin
  #
  #       crawler.on_page_error do |page|
  #         page.storable = false
  #         puts "Error #{page.url}"
  #       end
  #
  #       crawler.on_page_downloaded do |page|
  #         #return if page.error
  #
  #         puts "#{page.url}"
  #         url1 = URI("#{page.url}")
  #         hrefs << "#{page.body}"
  #
  #         if external == true
  #           page.doc.css("a").map do |link|
  #             href = link.attr("href")
  #             url2 = URI("#{href}")
  #             if url1.host != url2.host && !url2.host.nil?
  #               url = URI.parse(URI.encode("#{url2.scheme}" + "://" +"#{url2.host}"))
  #               puts "Link #{url}"
  #               hrefs << "#{url}"
  #             end
  #           end
  #         end
  #
  #       end
  #
  #     rescue
  #       nil
  #     end
  #
  #   end
  #
  #   # if hrefs.uniq.count.to_i > 0
  #   #   links = hrefs.uniq
  #   #   #Scrape.crawl(links, 0, false)
  #   #   hwacha = Hwacha.new
  #   #   hwacha.check(links) do |url, response|
  #   #     puts "Response: #{response.code} - URL: #{url}"
  #   #   end
  #   # end
  #   hrefs
  # end
  #
  # def self.nokogiri_links(pages)
  #
  #   links = []
  #   pages.map do |page|
  #     doc = Nokogiri::HTML(page)
  #     doc.css("a").map do |link|
  #       begin
  #         link_url = URI("#{link.attr('href')}")
  #         if !link_url.host.nil?
  #           url = URI.parse(URI.encode("#{link_url.scheme}" + "://" +"#{link_url.host}"))
  #           puts url
  #           links << "#{url}"
  #         end
  #       rescue
  #         nil
  #       end
  #     end
  #   end
  #   links
  # end
  #
  # def self.parse_links(links)
  #
  #   #parsed_links = []
  #   links.map do |l|
  #     uri = URI("#{l}")
  #     url = URI.parse(URI.encode("#{uri.scheme}" + "://" +"#{uri.host}"))
  #     #parsed_links << url
  #     puts Scrape.link_response(url)
  #   end
  #
  # end
  #
  # def self.link_response(link)
  #   hwacha = Hwacha.new
  #   hwacha.check(link) do |url, response|
  #
  #     if response.success?
  #       return "success #{url}"
  #     elsif response.timed_out?
  #       return "timed out #{url}"
  #     elsif response.code == 0
  #       return "bad url #{url}"
  #     else
  #       return "other #{url} - #{response}"
  #     end
  #
  #   end
  # end
  
  # def self.url_hosts_same?(url_1, url_2)
  #
  #   if url_1.nil? || url_2.nil?
  #     return false
  #   end
  #
  #   url_1_split = url_1.split '.'
  #   url_2_split = url_2.split '.'
  #
  #   # note: checks for domains with at least 1 period;
  #   # example: example.com
  #   # localhost will not work
  #   unless url_1_split.size > 1 && url_2_split.size >2
  #     return false
  #   end
  #
  #   url_1_base = url_1_split.pop(2).join('.')
  #   url_2_base = url_2_split.pop(2).join('.')
  #
  #   return url_1_base == url_2_base
  #
  # end
  
end