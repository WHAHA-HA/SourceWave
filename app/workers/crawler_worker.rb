class CrawlerWorker
  include Sidekiq::Worker
  
  #sidekiq_options queue: :crawler_worker
  
  def perform(site_id)
      #content = HashUtil.deep_symbolize_keys(page)
      #Page.create(url: "#{page[:url]}", status_code: "#{page[:status_code]}", mime_type: "#{page[:mime_type]}", length: "#{page[:length].to_s}", redirect_through: "#{page[:redirect_through]}", headers: "#{page[:headers]}", links: "#{page[:links][:links].join(',')}", crawl_id: "#{page[:myoptions][:crawl_id]}")
      #Page.create(url: "#{page[:url]}", status_code: "#{page[:status_code]}")
      #puts "the page length is #{page[:length].to_s} and redirect is #{page[:redirect_through]}"
      #puts "the page object is #{content}"
      
      site = Site.find(site_id.to_i)
      domain = Domainatrix.parse(site.base_url).domain
    
      opts = {
        'maxpages' => 100
      }
      Retriever::PageIterator.new("#{site.base_url}", opts) do |page|
      
        #links << page.links
        page.links.each do |l|
          internal = l.include?("#{domain}") ? true : false
          if internal == false
            res = Typhoeus.get("#{l}").response_code
          else
            res = ""
          end
          site.pages.delay.create(url: l.to_s, internal: internal, status_code: res)
        end

      end
      
  end
  
  def self.queue_size
    Sidekiq.redis do |conn|
      conn.llen("queue:#{get_sidekiq_options["queue"]}")
    end
  end
  
end