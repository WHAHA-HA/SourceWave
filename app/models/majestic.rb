class Majestic
  
  def self.get_info(options = {})
    
    if options[:class_name] == 'crawl'
      obj = Crawl.find(options[:obj_id])
      pages = obj.pages.where(available: 'true').map(&:simple_url)
    elsif options[:class_name] == 'site'
      obj = Site.find(options[:obj_id])
      pages = obj.pages.where(available: 'true').map(&:simple_url)
    else
      pages = Page.where(available: 'true').map(&:simple_url)
    end

    m = MajesticSeo::Api::Client.new.(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
    res = m.get_index_item_info(pages)
    
    res.items.map do |r|
      if obj
        page = obj.pages.where("simple_url = ?", r.response['Item']).first
      else
        page = Page.where("simple_url = ?", r.response['Item']).first
      end
      Page.update(page.id, citationflow: r.response['CitationFlow'], trustflow: r.response['TrustFlow'], trustmetric: r.response['TrustMetric'], refdomains: r.response['RefDomains'], backlinks: r.response['ExtBackLinks'])
    end
    
  end

end