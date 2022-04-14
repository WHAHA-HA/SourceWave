class UserDashboard < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :user_id

  def self.update_crawl_stats(user_id, options={})
    puts "updating user dashboard with metrics #{options}"
    dash = UserDashboard.using(:main_shard).where(user_id: user_id.to_i).first
    
    domains_crawled = options['domains_crawled'].nil? ? 0 : options['domains_crawled'].to_i
    domains_broken = options['domains_broken'].nil? ? 0 : options['domains_broken'].to_i
    domains_expired = options['domains_expired'].nil? ? 0 : options['domains_expired'].to_i
    finished_crawls = options['finished_crawls'].nil? ? 0 : options['finished_crawls'].to_i
    pending_crawls = options['pending_crawls'].nil? ? 0 : options['pending_crawls'].to_i
    running_crawls = options['running_crawls'].nil? ? 0 : options['running_crawls'].to_i
    
    dash.update(domains_crawled: dash.domains_crawled.to_i + domains_crawled, 
                domains_broken: dash.domains_broken.to_i + domains_broken, 
                domains_expired: dash.domains_expired.to_i + domains_expired,
                done_crawlers: dash.done_crawlers.to_i + finished_crawls,
                pending_crawlers: dash.pending_crawlers.to_i + pending_crawls,
                running_crawlers: dash.running_crawlers.to_i + running_crawls)
                
    # top_domains = Page.using(:processor).where('crawl_id = ? AND available = ?', options['crawl_id'].to_i, 'true').order(da: :desc).limit(10).map(&:id)
  end
  
  def self.add_pending_crawl(dashboard_id, options={})
    puts "adding a new pending crawl"
    dash = UserDashboard.using(:main_shard).find(dashboard_id)
    dash.update(pending_crawlers: dash.pending_crawlers.to_i + 1)
  end
  
  def self.add_running_crawl(dashboard_id, options={})
    puts "adding a new running crawl and removing 1 pending crawl"
    dash = UserDashboard.using(:main_shard).find(dashboard_id)
    dash.update(pending_crawlers: (dash.pending_crawlers.to_i - 1), running_crawlers: (dash.running_crawlers.to_i + 1))
  end
  
  def self.add_finished_crawl(user_id, options={})
    puts "adding a new done crawl and removing 1 running crawl"
    dash = UserDashboard.using(:main_shard).where(user_id: user_id.to_i).first
    dash.update(running_crawlers: (dash.running_crawlers.to_i - 1), done_crawlers: (dash.done_crawlers.to_i + 1))
  end

end
