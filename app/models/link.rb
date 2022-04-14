require 'domainatrix'

class Link < ActiveRecord::Base
  belongs_to :site
  has_one :process_links_batch
  # after_create :start_processing

  def self.start_processing(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    puts "Is it from DO or Heroku #{is_do}"
    puts "start_processing: start of method"
    stats = Sidekiq::Stats.new.queues["process_links"].to_i
    
    if stats < 500
      running_crawls = Rails.cache.read(["#{is_do}running_crawls"]).to_a
      puts "start_processing: list of running crawls #{running_crawls}"
      if !running_crawls.empty?
        if $redis.smembers("#{is_do}all_expired_ids").count < 5
        # if Rails.cache.read(["crawl/#{running_crawls[0]}/expired_ids"]).to_a.count < 5
          next_crawl_to_process = running_crawls[0]
          puts "next crawl to process #{next_crawl_to_process}"
          processing_link_ids = $redis.smembers("#{is_do}all_processing_ids").select{|obj| obj.include?("process-#{next_crawl_to_process}")}
          # processing_link_ids = Rails.cache.read(["crawl/#{next_crawl_to_process}/processing_batches/ids"]).to_a

          if !processing_link_ids.empty?
            puts "start_processing: there are more links to be processed"
            next_link_id_to_process = processing_link_ids[0]
            puts "the next link to be processed is #{next_link_id_to_process}"
            new_crawls_rotation = running_crawls.rotate
          
            puts "deleting process link id from batch for crawl #{options['crawl_id']}"
            $redis.srem("#{is_do}all_processing_ids", next_link_id_to_process)
            
            unparsed_redis_obj = $redis.get(next_link_id_to_process)
            
            
            if !unparsed_redis_obj.nil?
              redis_obj = JSON.parse(unparsed_redis_obj)
              puts "start_processing: the redis obj is #{redis_obj}"
        
              Rails.cache.write(["#{is_do}running_crawls"], new_crawls_rotation)
              Rails.cache.write(["#{is_do}current_processing_batch_id"], "#{next_link_id_to_process}")
            
              processor_name = redis_obj['processor_name']
              site_id = redis_obj['site_id'].to_i
              crawl_id = redis_obj['crawl_id'].to_i
              base_url = redis_obj['base_url']
              crawl = Crawl.using("#{processor_name}").where(id: crawl_id).first
              domain = Domainatrix.parse(base_url).domain

              Rails.cache.increment(["#{is_do}crawl/#{crawl_id}/processing_batches/total"])
              Rails.cache.increment(["#{is_do}crawl/#{crawl_id}/processing_batches/running"])

              if Rails.cache.read(["#{is_do}site/#{site_id}/processing_batches/total"], raw: true).to_i == 0
                site = Site.using("#{processor_name}").where(id: site_id).first
                puts "updating site and creating new starting variables for processing batch for the site #{site_id}"
                site.update(processing_status: 'running')
                Rails.cache.write(["#{is_do}site/#{site_id}/processing_batches/total"], 1, raw: true)
                Rails.cache.write(["#{is_do}site/#{site_id}/processing_batches/running"], 1, raw: true)
                Rails.cache.write(["#{is_do}site/#{site_id}/processing_batches/finished"], 0, raw: true)
              else
                puts 'incrementing process batch stats'
                Rails.cache.increment(["#{is_do}site/#{site_id}/processing_batches/total"])
                Rails.cache.increment(["#{is_do}site/#{site_id}/processing_batches/running"])
              end
    
              puts " process links on complete variables link id #{next_link_id_to_process} site id #{site_id} and crawl id #{crawl_id}"
    
              batch = Sidekiq::Batch.new
              batch.on(:complete, ProcessLinks, 'bid' => batch.bid, 'crawl_id' => crawl_id, 'site_id' => site_id, 'redis_id' => next_link_id_to_process, 'user_id' => crawl.user_id, 'crawl_type' => crawl.crawl_type, 'iteration' => crawl.iteration.to_i, 'processor_name' => processor_name)
          
              batch.jobs do
                redis_obj['links'].each{|l| ProcessLinks.perform_async(l, site_id, redis_obj['found_on'], domain, crawl_id, 'processor_name' => processor_name)}
              end
              
            else
              
              if running_crawls.map{|c|Crawl.running_count_for(c)}.sum{|c|c['processing_count']} > 0
                puts "Link: calling process link"
                Link.delay(:queue => "#{is_do}process_links").start_processing
              end
              
            end

          else
            if running_crawls.count > 1
              new_crawls_rotation = running_crawls.rotate
              Rails.cache.write(["#{is_do}running_crawls"], new_crawls_rotation)
              if running_crawls.map{|c|Crawl.running_count_for(c)}.sum{|c|c['processing_count']} > 0
                puts "start_processing: calling process link"
                Link.delay(:queue => "#{is_do}process_links").start_processing
              end
            end 
          end
        else
          puts "routing from process links to verify domain"
          VerifyNamecheap.delay(:queue => 'verify_domains').start
        end
      end
    end
    
  end
  
end
7