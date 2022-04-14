class GetRefDomains
  
  include Sidekiq::Worker
  
  def self.for_url(options={})
    url = Domainatrix.parse(options['url'])
    parsed_url = 'http://' + url.domain + "." + url.public_suffix
    m = MajesticSeo::Api::Client.new(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
    res = m.execute_command("GetRefDomains", {'item0' => parsed_url, 'Count' => 250})
    res_array = []
    res.body.children.xpath('//Row').each do |r|
      res = r.inner_text.split('|')
      res_array << {"url" => res[1], 'cf' => res[15], 'tf' => res[16]}
    end
    return res_array 
  end
  
end