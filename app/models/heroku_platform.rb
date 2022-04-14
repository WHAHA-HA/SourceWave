require 'platform-api'

class HerokuPlatform
  attr_accessor :api_token, :app_name, :log_url

  APP_NAME = ENV['heroku_app_name']
  API_TOKEN = ENV['heroku_api_token']

  def initialize
    @heroku ||= PlatformAPI.connect_oauth(API_TOKEN)
  end

  def formation_info(options = {})
    formation_type = options[:type].nil? ? "worker" : options[:type]
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    formation = @heroku.formation.info(app_name, formation_type)
  end

  def app_list
    @heroku.app.list
  end

  def formation_list(options = {})
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    formation = @heroku.formation.list(app_name)
  end

  def self.get_dyno_stats(options = {})
    puts "dyno stats method"
    dyno_type = options[:type].nil? ? "worker" : options[:type]
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    app = HerokuApp.find(options[:heroku_app_id])
    # formation = self.formation_info(type: dyno_type, app_name: options[:app_name])
    quantity = app.formation[dyno_type]
    # puts "here is the dyno formation #{formation}"
    # quantity = formation["quantity"]
    librato = DynoStats.new(heroku_app_id: options[:heroku_app_id])
    stats = {}
    quantity.to_i.times do |index|
      puts "getting the dyno stats for #{dyno_type}.#{index+1}"
      memory_total = librato.metrics(metric: "memory_total", source: "#{dyno_type}.#{index+1}")
      resident_memory = librato.metrics(metric: "memory_rss", source: "#{dyno_type}.#{index+1}")
      swap_memory = librato.metrics(metric: "memory_swap", source: "#{dyno_type}.#{index+1}")
      stats["#{dyno_type}.#{index+1}"] = {memory_total: memory_total, resident_memory: resident_memory, swap_memory: swap_memory}
    end
    puts "the dyno stats for #{dyno_type} are #{stats}"
    stats
  end

  def self.memory_stats(options = {})
    dyno_type = options[:type].nil? ? "worker" : options[:type]
    puts "here is the dyno type #{dyno_type}"
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    puts "here is the app name #{app_name}"
    stats = self.get_dyno_stats(type: dyno_type, app_name: app_name, heroku_app_id: options[:heroku_app_id])
    puts "here are the stats #{stats}"
    if !stats.empty?
      memory_stats = []
      stats.count.times do |index|
        memory_total = stats["#{dyno_type}.#{index+1}"][:memory_total]["value"]
        status = memory_total > 350 ? "red" : "green"

        memory_stats << status
      end
      puts "memory stats for #{dyno_type} are #{memory_stats}"
      return memory_stats
    end
end
  def scale_dynos(options = {})
    puts 'scaling dynos'
    dynos = options[:dynos].nil? ? ["worker"] : options[:dynos]
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    increase_quantity = options[:quantity].nil? ? 1 : options[:quantity]
    size = options[:size].nil? ? '1X' : options[:size]
    app = options[:heroku_app_id].nil? ? nil : HerokuApp.find(options[:heroku_app_id])
    dynos.each do |type|

      if app
        current_quantity = app.formation[type].to_i
        new_quantity = current_quantity + increase_quantity
        @heroku.formation.update(app_name, type, {"quantity"=>new_quantity, 'size'=>size})
        app.formation[type] = new_quantity
        app.save
      else
        current_quantity = formation_info(app_name: app_name, type: type)["quantity"]
        new_quantity = current_quantity + increase_quantity
        @heroku.formation.update(app_name, type, {"quantity"=>new_quantity, 'size'=>size})
      end

    end
  end

  def start_dyno(app_name, quantity, size, dyno)
    puts 'starting dyno'
    @heroku.formation.update(app_name, dyno, {"quantity"=>quantity, 'size'=>size})
  end

  def app_exists?(name)
    @heroku.app.list.collect do |app|
      app if app['name'] == name
    end.reject(&:nil?).any?
  end

  def self.create_new_app(from, to, options={})
    heroku = HerokuPlatform.new
    app = heroku.create_app(to)
    if !app.empty? && app['build_stack'].has_key?('id')
      slug = heroku.check_and_copy_slug(from, to)
      if !slug.empty? && slug['app'].has_value?(to)
        config = heroku.copy_config(from, to)
        if !config.empty?
          redis = heroku.add_redis_cloud(to)
          if !redis.empty? && redis['app'].has_value?(to)
            # librato = heroku.add_librato(to)
            # if !librato.empty? && librato['app'].has_value?(to)
              rack_envs = heroku.copy_rack_and_rails_env_again(from, to)
              if !rack_envs.empty?
                log_metrics = heroku.enable_log_runtime_metrics(to)
                if !log_metrics.empty? && log_metrics['enabled'] == true
                  # librato_env_vars = heroku.get_librato_env_variables_for(to)
                  redis_hash = heroku.get_redis_variables_for(to)
                  processlinks = heroku.start_dyno(to, 4, '2X', "processlinks")
                  if !processlinks.empty?
                    worker = heroku.start_dyno(to, 3, '2X', "worker")
                    if !worker.empty?
                      verifydomains = heroku.start_dyno(to, 3, '1X', "verifydomains")
                      if !verifydomains.empty?

                        puts 'app created successfully and restarting'
                        HerokuPlatform.restart_app(to)

                      end
                    end
                  end
                end
              end
            # end
            end
        end
      end
    end
  end

  def self.stop_app(app_name)
    heroku = HerokuPlatform.new
    puts "stopping app #{app_name}"
    dynos = ["worker", "processlinks", "verifydomains"]
    processlinks = heroku.start_dyno("#{app_name}", 0, '2X', "processlinks")
    if !processlinks.empty?
      worker = heroku.start_dyno("#{app_name}", 0, '2X', "worker")
      if !worker.empty?
        verifydomains = heroku.start_dyno("#{app_name}", 0, '1X', "verifydomains")
      end
    end
    # puts "stopping redis cloud add-on on app #{app_name}"
    # heroku.update_redis_cloud("#{app_name}")
    puts "app successfully stopped #{app_name}"
  end

  def self.start_app(app_name)
    heroku = HerokuPlatform.new
    puts "starting app #{app_name}"
    dynos = ["worker", "processlinks", "verifydomains"]
    processlinks = heroku.start_dyno("#{app_name}", 4, '2X', "processlinks")
    if !processlinks.empty?
      worker = heroku.start_dyno("#{app_name}", 3, '2X', "worker")
      if !worker.empty?
        verifydomains = heroku.start_dyno("#{app_name}", 3, '1X', "verifydomains")
      end
    end
    # puts "starting redis cloud add-on on app #{app_name}"
    # heroku.update_redis_cloud("#{app_name}", 30)
    puts "app successfully started #{app_name}"
  end


  def rate_limit
    @heroku.rate_limit.info
  end

  def self.migrate_db(app_name)
    puts "migrate_db: the app name is #{app_name}"
    heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
    heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')
    heroku.post_ps("#{app_name}", "rake db:migrate")
    sleep 5
    puts "migrate_db: database migrate and restarting app"
    heroku.post_ps("#{app_name}", "restart")
  end

  def set_db_config_vars(to, db_url)
    puts "here is the db_url #{db_url}"
    db_split = db_url.split(':')[1..3]
    db_user = db_split[0].split('//')[1]
    db_pass = db_split[1].split('@')[0]
    db_host = db_split[1].split('@')[1]
    db_port = db_split[2].split('/')[0].to_i
    db_name = db_split[2].split('/')[1]
    db_hash = {'DATABASE_URL' => db_url, 'DB_USER' => db_user, 'DB_PASS' => db_pass, 'DB_HOST' => db_host, 'DB_PORT' => db_port, 'DB_NAME' => db_name}

    puts "set_db_config_vars: db_hash is #{db_hash}"

    @heroku.config_var.update(to, db_hash)
    return db_hash
  end

  def get_librato_env_variables_for(app_name)
    puts "getting librato env variables for the app #{app_name}"
    vars = config_vars(app_name)
    librato_user = vars['LIBRATO_USER']
    librato_token = vars['LIBRATO_TOKEN']
    # redis_url = vars['REDISTOGO_URL']
    redis_url = vars['REDISCLOUD_URL']
    librato_hash = {librato_user: librato_user, librato_token: librato_token, redis_url: redis_url}
  end

  def get_redis_variables_for(app_name)
    puts "getting librato env variables for the app #{app_name}"
    vars = config_vars(app_name)
    redis_url = vars['REDISCLOUD_URL']
    redis_hash = {redis_url: redis_url}
  end

  def get_latest_api_release(app_name)
    puts "getting latest api release object"
    @heroku.release.list(app_name).to_a.last
  end

  def get_local_release_env_version
    puts "getting local release version from env var"
    ENV['RELEASE_VERSION']
  end

  def local_release_exists?
    puts "checking if local release version env var exists"
    ENV['RELEASE_VERSION'].nil? ? false : true
  end

  def set_release_env_and_slug_id(release_version, slug_id)
    puts "setting or updating new release version and slug id as env var"
    release_and_slug_hash = {'RELEASE_VERSION' => release_version, 'SLUG_ID' => slug_id}
     @heroku.config_var.update('sourcerevive', release_and_slug_hash)
  end

  def delete_app(app_name)
    puts "delete app method for the app #{app_name}"
    if "#{app_name}".include?('revivecrawler')
      puts "DANGER THE APP #{app_name} IS BEING DELETED"
      @heroku.app.delete(app_name)
    end
  end

  def restart_app(app_name)
    puts 'restarting app'
    @heroku.dyno.restart_all(app_name)
  end

  def self.restart_app(app_name)
    puts 'restarting app'
    heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
    heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')
    heroku.post_ps_restart("#{app_name}")
  end

  def add_pgbackups(to)
    puts 'adding pg backups'
    @heroku.addon.create(to, plan: "pgbackups")
  end

  def upgrade_postgres(to)
    puts 'upgrading postgres db'
    @heroku.addon.create(to, plan: "heroku-postgresql:standard-0")
  end

  def add_redis(to)
    puts 'adding redis'
    @heroku.addon.create(to, plan: "redistogo:smedium")
  end

  def update_redis_cloud(to, plan=500)
    puts 'updating redis cloud'
    @heroku.addon.update(to, plan: "rediscloud:#{plan}")
  end

  def add_redis_cloud(to, plan=500)
    puts 'adding redis cloud'
    @heroku.addon.create(to, plan: "rediscloud:#{plan}")
  end

  def add_librato(to)
    puts 'adding librato'
    @heroku.addon.create(to, plan: "librato")
  end

  def enable_log_runtime_metrics(app_name)
    puts 'enabling log runtime metrics'
    @heroku.app_feature.update(app_name, 'log-runtime-metrics', {'enabled'=>true})
  end

  def config_vars(app_name)
    @heroku.config_var.info(app_name)
  end

  def create_app(name)
    # logger.info "Creating #{name}"
    puts 'creating app'
    @heroku.app.create(name: name)
  end

  def copy_config(from, to)
    puts 'copying config'
    from_congig_vars = config_vars(from)
    from_congig_vars = from_congig_vars.except!('HEROKU_POSTGRESQL_RED_URL', 'HEROKU_POSTGRESQL_AMBER_URL', 'HEROKU_POSTGRESQL_BROWN_URL', 'HEROKU_POSTGRESQL_COPPER_URL', 'HEROKU_POSTGRESQL_NAVY_URL', 'HEROKU_POSTGRESQL_WHITE_URL', 'PROXIMO_URL', 'LIBRATO_USER', 'LIBRATO_PASSWORD', 'LIBRATO_TOKEN', 'REDISTOGO_URL', 'REDISCLOUD_URL')
    @heroku.config_var.update(to, from_congig_vars)
  end

  def check_and_copy_slug(from, to)
    puts 'checking and copying slug'
    # latest_api_release = get_latest_api_release(from)

    heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
    heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')

    version_id = heroku.get_releases(from).body.last['name'].scan(/\d+/)[0].to_i
    puts "the latest slug id is #{version_id }"

    latest_api_release = @heroku.release.info('reviveprocessor', version_id)
    set_release_env_and_slug_id(version_id, latest_api_release['slug']['id'])
    @heroku.release.create(to, slug: latest_api_release['slug']['id'])

  end

  def copy_rack_and_rails_env_again(from, to)
    puts 'copying rack and rails env again'
    env_to_update = get_env_vars_for(from, ['RACK_ENV', 'RAILS_ENV'])
    env_to_update["REDIS_PROVIDER"] = 'REDISCLOUD_URL'
    @heroku.config_var.update(to, env_to_update) unless env_to_update.empty?
  end

  def get_env_vars_for(app_name, options=[])
    environments = {}
    options.each do |var|
      conf_var = @heroku.config_var.info(app_name)[var]
      if conf_var
        environments[var] = conf_var
      end
    end
    environments
  end

end
