require 'domainatrix'
class MozStats
  include Sidekiq::Worker
  sidekiq_options :queue => :verify_domains

  def self.perform(page_id, simple_url, options={})
    puts 'moz perform on perform'
    processor_name = options['processor_name']
    client = Linkscape::Client.new(:accessID => "member-8967f7dff3", :secret => "8b98d4acd435d50482ebeded953e2331")
    response = client.urlMetrics([simple_url], :cols => :all)
    
    response.data.map do |r|
      begin
        puts "moz block perform regular"
        url = Domainatrix.parse("#{r[:uu]}")
        parsed_url = url.domain + "." + url.public_suffix
        Page.using("#{processor_name}").update(page_id, da: r[:pda].to_f, pa: r[:upa].to_f)
      rescue
        puts "moz block perform zero"
        Page.using("#{processor_name}").update(page_id, da: 0, pa: 0)
      end
    end
  end

  def perform(page_id, simple_url, options={})
    puts "MozStats asynchronous for page #{page_id}"
    puts 'moz perform on perform'
    processor_name = options['processor_name']
    client = Linkscape::Client.new(:accessID => "member-8967f7dff3", :secret => "8b98d4acd435d50482ebeded953e2331")
    response = client.urlMetrics([simple_url], :cols => :all)
    
    response.data.map do |r|
      begin
        puts "moz block perform regular"
        url = Domainatrix.parse("#{r[:uu]}")
        parsed_url = url.domain + "." + url.public_suffix
        Page.using("#{processor_name}").update(page_id, da: r[:pda].to_f, pa: r[:upa].to_f)
      rescue
        puts "moz block perform zero"
        Page.using("#{processor_name}").update(page_id, da: 0, pa: 0)
      end
    end
  end
  
  def self.start(page_id)
    MozStats.perform_async(page_id)
  end
  
end