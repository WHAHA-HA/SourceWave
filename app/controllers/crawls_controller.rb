class CrawlsController < ApplicationController
  before_action :authorize, :except => [:api_create, :migrate_db, :process_new_crawl, :shut_down_crawl]
  skip_before_action :verify_authenticity_token, :only => [:api_create, :migrate_db, :process_new_crawl, :shut_down_crawl]
  before_action :verify_subscription, :only => [:create, :create_keyword_crawl, :create_reverse_crawl]

  def index
    processor_names = ['processor', 'processor_one', 'processor_two', 'processor_three', 'processor_four']
    crawls_array = []
    processor_names.each do |processor|
      # crawls_array << Crawl.using("#{processor}").where(user_id: current_user.id).order('created_at').limit(10).flatten
      begin
        crawls_array << Crawl.using("#{processor}").where(user_id: current_user.id)
      rescue

      end
    end
    page = params[:page].nil? ? 1 : params[:page]
    @crawls = crawls_array.flatten.sort_by{|record| record.created_at}.reverse.paginate(:page => page, :per_page => 10)

  end

  def running

    processor_names = ['processor', 'processor_one', 'processor_two', 'processor_three', 'processor_four']
    crawls_array = []
    processor_names.each do |processor|
      # crawls_array << Crawl.using("#{processor}").where(status: 'running', user_id: current_user.id).order('created_at').limit(10).flatten
      crawls_array << Crawl.using("#{processor}").where(status: 'running', user_id: current_user.id)
    end
    page = params[:page].nil? ? 1 : params[:page]
    @crawls = crawls_array.flatten.sort_by{|record| record.created_at}.reverse.paginate(:page => page, :per_page => 10)

    # @crawls = Crawl.using(:processor).where(status: 'running', user_id: current_user.id).order('created_at').page(params[:page]).per_page(10)
  end

  def finished

    processor_names = ['processor', 'processor_one', 'processor_two', 'processor_three', 'processor_four']
    crawls_array = []
    processor_names.each do |processor|
      # crawls_array << Crawl.using("#{processor}").where(status: 'finished', user_id: current_user.id).order('created_at').limit(10).flatten
      crawls_array << Crawl.using("#{processor}").where(status: 'finished', user_id: current_user.id).order('created_at').flatten
    end
    page = params[:page].nil? ? 1 : params[:page]
    @crawls = crawls_array.flatten.paginate(:page => page, :per_page => 10)

    # @crawls = Crawl.using(:processor).where(status: 'finished', user_id: current_user.id).order('created_at').page(params[:page]).per_page(10)
  end

  def show
    processor_name = params['processor_name']
    @project = Crawl.using("#{processor_name}").where(user_id: current_user.id, id: params[:id]).first


    # if @project.status == 'running' && !@project.redis_url.nil?
    #   begin
    #     redis = ActiveSupport::Cache.lookup_store(:redis_store, @project.redis_url)
    #     urls_found = "crawl/#{@project.id}/urls_found"
    #     expired_domains = "crawl/#{@project.id}/expired_domains"
    #     broken_domains = "crawl/#{@project.id}/broken_domains"
    #     progress = "crawl/#{@project.id}/progress"
    #     stats = redis.read_multi(urls_found, expired_domains, broken_domains, progress, raw: true)
    #     @urls_found = stats[urls_found].to_i
    #     @broken_domains = stats[broken_domains].to_i
    #     @expired_domains = stats[expired_domains].to_i
    #     @progress = stats[progress].to_f
    #   rescue
    #     @urls_found = @project.total_urls_found.to_i
    #     @broken_domains = @project.total_broken.to_i
    #     @expired_domains = @project.total_expired.to_i
    #   end
    # else
      @urls_found = @project.total_urls_found.to_i
      @broken_domains = @project.total_broken.to_i
      @expired_domains = @project.total_expired.to_i
    # end

    @stats_chart = Crawl.crawl_stats(@broken_domains, @expired_domains)
    # @sites = Site.find(@project.process_links_batches.map(&:site_id))
    @sites = @project.sites.page(params[:page]).per_page(10)
    @top_domains = @project.pages.where(available: 'true').limit(5)
  end

  def new
    @project = current_user.crawls.new

  end

  def new_keyword_crawl
    @project = current_user.crawls.new
  end

  def create
    puts "saving crawls...."
    Rails.logger.info "Some debugging info"
    Crawl.delay.save_new_crawl(current_user.id, params[:urls], params[:crawl])
    redirect_to crawls_path
  end

  def new_reverse_crawl
    @project = current_user.crawls.new
  end

  def create_reverse_crawl
    Crawl.delay.save_new_reverse_crawl(current_user.id, params[:url], params[:crawl])
    redirect_to crawls_path
  end


  def edit
    @project = Crawl.using(params["processor_name"]).find(params[:id])
    total_minutes = @project.total_minutes.to_f
    if total_minutes > 0
      if total_minutes > 60
        split_total_time = (total_minutes.to_f/60.to_f).round(2).to_s.split('.')
        @hours = split_total_time[0]
        @minutes = split_total_time[1]
      else
        @hours = 0
        @minutes = total_minutes
      end
    else
      @hours = 0
      @minutes = 0
    end
  end

  def create_keyword_crawl
    Crawl.delay.save_new_keyword_crawl(current_user.id, params[:crawl][:keyword], params[:crawl])
    redirect_to crawls_path
  end

  def process_new_crawl
    @json = JSON.parse(request.body.read)
    puts "crawl to process hash #{@json["options"]}"
    Crawl.delay.decision_maker(@json["options"])
    render :layout => false
  end

  def api_create
    @json = JSON.parse(request.body.read)
    puts "here is the json hash #{@json["options"]}"
    Crawl.delay.start_crawl(@json["options"])
    SidekiqStats.delay.start(@json["options"])
    render :layout => false
  end

  def migrate_db
    @json = JSON.parse(request.body.read)
    processor_name = @json["options"]['processor_name']
    if @json["options"]["iteration"].to_i == 1

      crawl = Crawl.using("#{processor_name}").find(@json["options"]["crawl_id"].to_i)
      master_url = ENV['DATABASE_URL']
      slave_keys = ENV.keys.select{|k| k =~ /HEROKU_POSTGRESQL_.*_URL/}
      db_url_name = (slave_keys - ["HEROKU_POSTGRESQL_COPPER_URL", "HEROKU_POSTGRESQL_AMBER_URL","HEROKU_POSTGRESQL_NAVY_URL","HEROKU_POSTGRESQL_WHITE_URL", "HEROKU_POSTGRESQL_BROWN_URL"])
      puts "migrate db: the db url name is #{db_url_name[0]}"
      db_url = ENV[db_url_name[0]]

      db_split = db_url.split(':')[1..3]

      db_user = db_split[0].split('//')[1]
      db_pass = db_split[1].split('@')[0]
      db_host = db_split[1].split('@')[1]
      db_port = db_split[2].split('/')[0].to_i
      db_name = db_split[2].split('/')[1]

      crawl.update(db_url: db_url)
      puts "setting the database variables"

      heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
      heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')
      heroku.put_config_vars("revivecrawler#{@json["options"]["crawl_id"]}", 'DATABASE_URL' => db_url, 'DB_USER' => db_user, 'DB_PASS' => db_pass, 'DB_HOST' => db_host, 'DB_PORT' => db_port, 'DB_NAME' => db_name)

      # heroku.set_db_config_vars("revivecrawler#{@json["options"]["crawl_id"]}", db_url)

    else

      puts "second iteration about to migrate the database"
      heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
      heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')
      heroku.post_ps("revivecrawler#{@json["options"]["crawl_id"]}", "rake db:migrate")
      sleep 5
      puts "migrate_db: database migrate and restarting app"
      heroku.post_ps("revivecrawler#{@json["options"]["crawl_id"]}", "restart")

    end
    render :layout => false
  end

  def destroy
    crawl = HerokuApp.using(params["processor_name"]).find(params[:id])
    crawl.destroyl
    redirect_to crawls_path
  end

  def delete_crawl
    crawl = Crawl.using(params["processor_name"]).find(params[:id])
    crawl.delete
    redirect_to crawls_path
  end

  def start_crawl
    Api.delay.process_new_crawl(user_id: current_user.id, 'processor_name' => params['processor_name'])
    redirect_to crawls_path
  end

  def stop_crawl
    puts "stop the crawl with the ID #{params[:id]} in the processor #{params['processor_name']}"
    # Crawl.delay.stop_crawl(params[:id], 'processor_name' => params['processor_name'])
    # Crawl.delay.shut_down('crawl_id' => params[:id])
    Api.delay.stop_crawl('crawl_id' => params[:id], 'processor_name' => params['processor_name'])
    redirect_to crawls_path
  end

  def shut_down_crawl
    @json = JSON.parse(request.body.read)
    crawl_id = @json["options"]['crawl_id']
    processor_name = @json["options"]['processor_name']
    Crawl.delay.shut_down('crawl_id' => crawl_id, 'processor_name' => processor_name)
    render :layout => false
  end

  def verify_subscription
    redirect_to crawls_path, alert: "Upgrade your Revive subscription to run a crawl" unless current_user.active? || true
  end

end
