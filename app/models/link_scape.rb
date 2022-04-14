require 'domainatrix'
class LinkScape
  
  def self.get_info(options = {})
    
    if options[:class_name] == 'crawl'
      obj = Crawl.find(options[:obj_id])
      parsed_urls = LinkScape.urls_to_array(class_name: options[:class_name], obj_id: options[:obj_id])
    elsif options[:class_name] == 'site'
      obj = Site.find(options[:obj_id])
      parsed_urls = LinkScape.urls_to_array(class_name: options[:class_name], obj_id: options[:obj_id])
    else
      parsed_urls = LinkScape.urls_to_array
    end

    if !parsed_urls.empty?
      client = Linkscape::Client.new(:accessID => "member-8967f7dff3", :secret => "8b98d4acd435d50482ebeded953e2331")
      response = client.urlMetrics(parsed_urls, :cols => :all)
    
      response.data.map do |r|
        url = Domainatrix.parse("#{r[:uu]}")
        parsed_url = url.domain + "." + url.public_suffix
        if obj
          page = obj.pages.where("simple_url = ?", parsed_url).first
        else
          page = Page.where("simple_url = ?", parsed_url).first
        end
        Page.update(page.id, da: r[:pda], pa: r[:upa])
      end
    end
    
  end
  
  def self.urls_to_array(options = {})
    
    if options[:class_name] == 'crawl'
      obj = Crawl.find(options[:obj_id])
    elsif options[:class_name] == 'site'
      obj = Site.find(options[:obj_id])
    end

    parsed_urls = []
    if obj
      pages = obj.pages.where(available: 'true').map(&:simple_url)
    else
      pages = Page.where(available: 'true').map(&:simple_url)
    end
    pages.map do |p|
      parsed_urls << URI.encode("www.#{p}")
    end
    parsed_urls
    
  end
  
end