class Page < ActiveRecord::Base
  belongs_to :site
  # after_create :verify_namecheap
  
  def self.verify_namecheap(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    redis_id = options['redis_id']
    redis_obj = JSON.parse($redis.get(redis_id))
    puts "verifying namecheap for redis obj #{redis_obj}"
    status_code = redis_obj['status_code']
    internal = redis_obj['internal']
    crawl_id = redis_obj['crawl_id']
    processor_name = redis_obj['processor_name']
    site_id = redis_obj['site_id']
    
    if status_code == '0' && internal == false
      puts "going to verify namecheap"
      VerifyNamecheap.perform_async(redis_id, crawl_id, 'processor_name' => processor_name)
    elsif status_code == '404'
      Rails.cache.increment(["#{is_do}crawl/#{crawl_id}/broken_domains"])
      Rails.cache.increment(["#{is_do}site/#{site_id}/broken_domains"])
    end
  end

  def verify_namecheap(options={})
    #check if it's from Digital Ocean API
    is_do = options['is_do'].present? ? 'do_' : '';
    puts 'verifying namecheap'
    if status_code == '0' && internal == false
      VerifyNamecheap.perform_async(redis_id, crawl_id, 'processor_name' => processor_name)
    elsif status_code == '404'
      Rails.cache.increment(["#{is_do}crawl/#{crawl_id}/broken_domains"])
      Rails.cache.increment(["#{is_do}site/#{site_id}/broken_domains"])
    end
  end
  
  def self.to_csv
    attributes = %w[simple_url da pa trustflow citationflow refdomains backlinks found_on]
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |page|
        csv << page.attributes.values_at(*attributes)
      end
    end
  end
  
  def self.get_id(redis_id, simple_url, options={})
    puts "get id: on method"
    page = Page.using("#{options['processor_name']}").find_by_redis_id(redis_id)
    puts "get id: the page id is #{page.id}"
    MozStats.perform_async(page.id, simple_url, 'processor_name' => options['processor_name'])
    MajesticStats.perform_async(page.id, simple_url, 'processor_name' => options['processor_name'])
  end
  
  def self.find_with_id(page_id, url)
    processors_array = ['processor', 'processor_one', 'processor_two', 'processor_three', 'processor_four']
    page = processors_array.map do |p|
      page = Page.using("#{p}").where(id: page_id.to_i, simple_url: url).first
      {'processor_name' => p, 'page' => page} unless page.nil?
    end.compact[0]
  end
  
end
