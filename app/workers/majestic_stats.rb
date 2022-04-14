class MajesticStats
  include Sidekiq::Worker
  sidekiq_options :queue => :verify_domains

  def perform(page_id, simple_url, options={})
    puts 'majestic perform on perform'
    processor_name = options['processor_name']
    m = MajesticSeo::Api::Client.new(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
    res = m.get_index_item_info([simple_url])
    
    res.items.each do |r|
      puts "majestic block perform #{r.response['CitationFlow']}"
      Page.using("#{processor_name}").update(page_id, citationflow: r.response['CitationFlow'].to_f, trustflow: r.response['TrustFlow'].to_f, trustmetric: r.response['TrustMetric'].to_f, refdomains: r.response['RefDomains'].to_i, backlinks: r.response['ExtBackLinks'].to_i)
    end
  end
  
  def on_complete(status, options)
    batch = VerifyMajesticBatch.where(batch_id: "#{options['bid']}").first
    if !batch.nil?
      batch.update(status: 'finished')
      puts 'finished verifying all majestic domains'
    end
  end
  
  def self.start(page_id)
    puts 'majestic perform on perform'
    page = Page.find(page_id)
    
    m = MajesticSeo::Api::Client.new(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
    res = m.get_index_item_info([page.simple_url])
    
    res.items.each do |r|
      puts "majestic block perform #{r.response['CitationFlow']}"
      Page.update(page.id, citationflow: r.response['CitationFlow'].to_f, trustflow: r.response['TrustFlow'].to_f, trustmetric: r.response['TrustMetric'].to_f, refdomains: r.response['RefDomains'].to_i, backlinks: r.response['ExtBackLinks'].to_i)
    end
  end

  def self.start(page_id)
    MajesticStats.perform_async(page_id)
  end
  
end