require 'domainatrix'
require 'unirest'

class VerifyNamecheap
  include Sidekiq::Worker
  sidekiq_options :queue => :verify_domains
  sidekiq_options :retry => false
  
  def perform(redis_id)

    # START OF VERIFY DOMAIN STATUS
    page_from_redis = $redis.get(redis_id)
    puts "the page from redis is #{page_from_redis}"
    if !page_from_redis.nil?
      page = JSON.parse(page_from_redis)
      puts "verify namecheap: the page object is #{page}"

      begin
        puts 'found page to verify namecheap'
        url = Domainatrix.parse("#{page['url']}")
        if !url.domain.empty? && !url.public_suffix.empty?
          puts "here is the parsed url #{page['url']}"
          parsed_url = url.domain + "." + url.public_suffix
          
          if !Rails.cache.read(["crawl/#{page['crawl_id']}/checked"]).include?(parsed_url)
            puts "checking url #{parsed_url} on namecheap"
            avl = Set.new(Rails.cache.read(["crawl/#{page['crawl_id']}/checked"]))
            Rails.cache.write(["crawl/#{page['crawl_id']}/checked"], avl.add("#{parsed_url}").to_a)
            domain_is_available = Whois.whois("#{parsed_url}").available?
            # uri = URI.parse("https://nametoolkit-name-toolkit.p.mashape.com/beta/whois/#{parsed_url}")
            # http = Net::HTTP.new(uri.host, uri.port)
            # http.use_ssl = true
            # request = Net::HTTP::Get.new(uri.request_uri)
            # request["X-Mashape-Key"] = "6CWhVxnwLhmshW8UaLSYUSlMocdqp1kkOR4jsnmEFj0MrrHB5T"
            # request["Accept"] = "application/json"
            # response = http.request(request)
            # json = JSON.parse(response.read_body)
            puts "the domain verification response is #{domain_is_available}"
            tlds = [".gov", ".edu", ".nl"]
            if domain_is_available == true && !Rails.cache.read(["crawl/#{page['crawl_id']}/available"]).include?("#{parsed_url}") && !tlds.any?{|tld| parsed_url.include?(tld)}         
            # if json['available'].to_s == 'true' && !Rails.cache.read(["crawl/#{page['crawl_id']}/available"]).include?("#{parsed_url}") && !tlds.any?{|tld| parsed_url.include?(tld)}
              puts "saving verified domain with the following data processor_name: #{page['processor_name']}, status_code: #{page['status_code']}, url: #{page['url']}, internal: #{page['internal']}, site_id: #{page['site_id']}, found_on: #{page['found_on']}, simple_url: #{parsed_url}, verified: true, available: #{domain_is_available}, crawl_id: #{page['crawl_id']}"
              
              set = Set.new(Rails.cache.read(["crawl/#{page['crawl_id']}/available"]))
              Rails.cache.write(["crawl/#{page['crawl_id']}/available"], set.add("#{parsed_url}").to_a)
              
              new_page = Page.using("#{page['processor_name']}").create(status_code: page['status_code'], url: page['url'], internal: page['internal'], site_id: page['site_id'].to_i, found_on: page['found_on'], simple_url: parsed_url, verified: true, available: "#{domain_is_available}", crawl_id: page['crawl_id'].to_i, redis_id: redis_id)
              # new_page = Page.using("#{page['processor_name']}").create(status_code: page['status_code'], url: page['url'], internal: page['internal'], site_id: page['site_id'].to_i, found_on: page['found_on'], simple_url: parsed_url, verified: true, available: "#{json['available']}", crawl_id: page['crawl_id'].to_i, redis_id: redis_id)
              puts "VerifyNamecheap: saved verified domain #{new_page.id}"

              Rails.cache.increment(["crawl/#{page['crawl_id']}/expired_domains"])
              Rails.cache.increment(["site/#{page['site_id']}/expired_domains"])
      
              page_hash = {}
      
              puts 'sync moz perform on perform'
              access_id = "mozscape-74780478ca"
              secret_key = "90b5ab577f4c0aa18efe17063ca00950"
              expires = Time.now.to_i + 300
              string_to_sign = "#{access_id}\n#{expires}"
              binary_signature = OpenSSL::HMAC.digest('sha1', secret_key, string_to_sign)
              url_safe_signature = CGI::escape(Base64.encode64(binary_signature).chomp)
              response = Unirest.get "http://lsapi.seomoz.com/linkscape/url-metrics/#{parsed_url}/?AccessID=#{access_id}&Expires=#{expires}&Signature=#{url_safe_signature}&Cols=103079215104"
              moz_hash = JSON.parse response.raw_body
              puts "the moz response is #{moz_hash}"
              # response = VerifyNamecheap.moz(parsed_url)
              
              if !moz_hash.empty?
                page_hash[:da] = moz_hash['pda'].to_f
                page_hash[:pa] = moz_hash['upa'].to_f
              else
                puts "the moz response is empty"
              end
      
              puts 'finished checking moz sync'
      
              puts 'sync majestic perform on perform'
              m = MajesticSeo::Api::Client.new(api_key: ENV['majestic_api_key'], environment: ENV['majestic_env'])
              res = m.get_index_item_info([parsed_url])

              res.items.each do |r|
                puts "majestic block perform #{r.response['CitationFlow']}"
                page_hash[:citationflow] = r.response['CitationFlow'].to_f
                page_hash[:trustflow] = r.response['TrustFlow'].to_f
                page_hash[:trustmetric] = r.response['TrustMetric'].to_f
                page_hash[:refdomains] = r.response['RefDomains'].to_i
                page_hash[:backlinks] = r.response['ExtBackLinks'].to_i
              end
      
              puts 'finished checking majestic sync'
      
              puts "VerifyNamecheap about to save page #{page_hash}"
              Page.using("#{page['processor_name']}").update(new_page.id, page_hash)
            else
              puts 'url already included'
            end
          end
        else
          puts 'url already checked'
        end
      rescue
        puts "VerifyNamecheap failed"
        # puts "VerifyNamecheap: calling start perform method 2"
        # VerifyNamecheap.delay.start
      end
      
    else
      puts "VerifyNamecheap no page found on redis"
      puts "VerifyNamecheap: calling start perform method 3"
      if $redis.smembers('all_expired_ids').count > 1
        VerifyNamecheap.delay(:queue => 'verify_domains').start
      end
    end
    
    # END OF VERIFY DOMAIN STATUS

  end
  
  def on_complete(status, options)
    puts "VerifyNamecheap: calling start on_complete"
    running = Rails.cache.read(['running_crawls']).to_a
    if running.map{|c|Crawl.running_count_for(c)}.sum{|c|c['expired_count']} > 0
      VerifyNamecheap.delay(:queue => 'verify_domains').start
    else 
      if running.map{|c|Crawl.running_count_for(c)}.sum{|c|c['processing_count']} > 0
        puts "VerifyNamecheap: calling process link"
        Link.delay(:queue => 'process_links').start_processing
      end
    end
  end
  
  def self.start(options={})
    puts "VerifyNamecheap: start method"
    expired_rotation = Rails.cache.read(['expired_rotation']).to_a
    puts "the current expired crawl rotation is #{expired_rotation}"
    
    if options['crawl_id'].nil?
      next_crawl_to_process = expired_rotation[0]
    else
      next_crawl_to_process = options['crawl_id'].to_i
    end

    all_expired_ids = $redis.smembers('all_expired_ids').select{|objs| objs.include?("expired-#{next_crawl_to_process}")}.to_a
    
    if !all_expired_ids.empty?
      next_expired_id_to_verify = all_expired_ids[0]
      puts "updating expired ids array and removing #{next_expired_id_to_verify}"
      Rails.cache.write(['domain_being_verified'], [next_expired_id_to_verify])
      puts "the domain to be verified is #{next_expired_id_to_verify}"
      new_expired_rotation = expired_rotation.rotate
      Rails.cache.write(['expired_rotation'], new_expired_rotation)
      $redis.srem 'all_expired_ids', next_expired_id_to_verify
      # Rails.cache.write(["crawl/#{next_crawl_to_process}/expired_ids"], all_expired_ids-[next_expired_id_to_verify])
      
      batch = Sidekiq::Batch.new
      batch.on(:complete, VerifyNamecheap)
      batch.jobs do
        puts "VerifyNamecheap: about to verify domain for crawl #{next_crawl_to_process} with id #{next_expired_id_to_verify}"
        VerifyNamecheap.perform_async(next_expired_id_to_verify)
      end

    elsif expired_rotation.count > 1
      puts "there are no expired domains to be verified for this crawl #{next_crawl_to_process}"
      new_expired_rotation = expired_rotation.rotate
      Rails.cache.write(['expired_rotation'], new_expired_rotation)
      next_to_verify = expired_rotation.map{|c|Crawl.running_count_for(c)}.select{|c|c['expired_count'].to_i > 0}[0]
      if !next_to_verify.nil?
        puts 'VerifyNamecheap there are more crawls in this rotation'
        VerifyNamecheap.delay(:queue => 'verify_domains').start('crawl_id' => next_to_verify['crawl_id'].to_i)
      end
    end
  end
  
  def self.moz(url)
    access_id = "mozscape-74780478ca"
    secret_key = "90b5ab577f4c0aa18efe17063ca00950"
    expires = Time.now.to_i + 300
    string_to_sign = "#{access_id}\n#{expires}"
    binary_signature = OpenSSL::HMAC.digest('sha1', secret_key, string_to_sign)
    url_safe_signature = CGI::escape(Base64.encode64(binary_signature).chomp)
    response = Unirest.get "http://lsapi.seomoz.com/linkscape/url-metrics/#{url}/?AccessID=#{access_id}&Expires=#{expires}&Signature=#{url_safe_signature}&Cols=103079215104"
    return JSON.parse response.raw_body
  end
  
  
end