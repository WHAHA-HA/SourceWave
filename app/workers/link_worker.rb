require 'domainatrix'

class LinkWorker
  
  include Sidekiq::Worker
  
  def perform(link_id)
    
    link = Link.find(link_id)
    links = link.links
    site = Site.find(link.site_id)
    hydra = Typhoeus::Hydra.new
    domain = Domainatrix.parse(site.base_url).domain
    
    links.map do |l|
      request = Typhoeus::Request.new(l, method: :head, followlocation: true)
      # response = Typhoeus.head(l, followlocation: true)
      #
      # internal = l.include?("#{domain}") ? true : false
      # Page.delay.create(status_code: "#{response.code}", url: "#{l}", internal: internal, site_id: site.id)
      
      request.on_complete do |response|
        # if response.success?
#           puts "hell yeah"
#         elsif response.timed_out?
#           # aw hell no
#           puts "got a time out"
#         elsif response.code == 0
#           # Could not get an http response, something's wrong.
#           puts "#{response.return_message}"
#         else
#           # Received a non-successful http response.
#           puts "HTTP request failed: #{response.code}"
#         end

        internal = l.include?("#{domain}") ? true : false
        Page.delay.create(status_code: "#{response.code}", url: "#{l}", internal: internal, site_id: site.id, found_on: "#{link.found_on}")
      end

      hydra.queue(request)
    end
    
    hydra.run
    
  end
  
end