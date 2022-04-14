#!/usr/bin/ruby
require 'platform-api'
#we're using droplet API
require 'droplet_kit'

class DropletPlatform
  attr_accessor :api_token, :app_name, :log_url

  APP_NAME = ENV['droplet_app_name']
  API_TOKEN = ENV['droplet_api_token']

  def initialize
    @client ||= DropletKit::Client.new(access_token: API_TOKEN)
  end

  def formation_info(options = {})
    formation_type = options[:type].nil? ? "worker" : options[:type]
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    formation = @client.formation.info(app_name, formation_type)
  end

  def app_list
    @client.app.list
  end


  def scale_droplets(options = {})
    puts 'scaling droplets'
    droplets = options[:droplets].nil? ? ["worker"] : options[:droplets]
    app_name = options[:app_name].nil? ? APP_NAME : options[:app_name]
    increase_quantity = options[:quantity].nil? ? 1 : options[:quantity]
    size = options[:size].nil? ? '1X' : options[:size]
    app = options[:heroku_app_id].nil? ? nil : HerokuApp.find(options[:heroku_app_id])
    droplets.each do |type|

      if app
        current_quantity = app.formation[type].to_i
        new_quantity = current_quantity + increase_quantity
        @client.formation.update(app_name, type, {"quantity"=>new_quantity, 'size'=>size})
        app.formation[type] = new_quantity
        app.save
      else
        current_quantity = formation_info(app_name: app_name, type: type)["quantity"]
        new_quantity = current_quantity + increase_quantity
        @client.formation.update(app_name, type, {"quantity"=>new_quantity, 'size'=>size})
      end

    end
  end

  def start_droplet(app_name, quantity, size, droplet)
    puts 'starting droplet'
    @client.formation.update(app_name, droplet, {"quantity"=>quantity, 'size'=>size})
  end

  def app_exists?(name)
    @client.app.list.collect do |app|
      app if app['name'] == name
    end.reject(&:nil?).any?
  end

  def self.create_new_app(from, to, options={})
    heroku = DropletPlatform.new
    app = droplet.create_app(to)
    if !app.empty? && app['build_stack'].has_key?('id')
      slug = droplet.check_and_copy_slug(from, to)
      if !slug.empty? && slug['app'].has_value?(to)
        config = droplet.copy_config(from, to)
        if !config.empty?
          redis = droplet.add_redis_cloud(to)
          if !redis.empty? && redis['app'].has_value?(to)
            # librato = droplet.add_librato(to)
            # if !librato.empty? && librato['app'].has_value?(to)
            rack_envs = droplet.copy_rack_and_rails_env_again(from, to)
            if !rack_envs.empty?
              log_metrics = droplet.enable_log_runtime_metrics(to)
              if !log_metrics.empty? && log_metrics['enabled'] == true
                # librato_env_vars = droplet.get_librato_env_variables_for(to)
                redis_hash = droplet.get_redis_variables_for(to)
                processlinks = droplet.start_droplet(to, 4, '2X', "processlinks")
                if !processlinks.empty?
                  worker = droplet.start_droplet(to, 3, '2X', "worker")
                  if !worker.empty?
                    verifydomains = droplet.start_droplet(to, 3, '1X', "verifydomains")
                    if !verifydomains.empty?


                      puts 'app created successfully and restarting'
                      DropletPlatform.restart_app(to)


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
    heroku = DropletPlatform.new
    puts "stopping app #{app_name}"
    droplets = ["worker", "processlinks", "verifydomains"]
    processlinks = droplet.start_droplet("#{app_name}", 0, '2X', "processlinks")
    if !processlinks.empty?
      worker = droplet.start_droplet("#{app_name}", 0, '2X', "worker")
      if !worker.empty?
        verifydomains = droplet.start_droplet("#{app_name}", 0, '1X', "verifydomains")
      end
    end
    # puts "stopping redis cloud add-on on app #{app_name}"
    # droplet.update_redis_cloud("#{app_name}")
    puts "app successfully stopped #{app_name}"
  end

  def self.start_app(app_name)
    heroku = DropletPlatform.new
    puts "starting app #{app_name}"
    droplets = ["worker", "processlinks", "verifydomains"]
    processlinks = droplet.start_droplet("#{app_name}", 4, '2X', "processlinks")
    if !processlinks.empty?
      worker = droplet.start_droplet("#{app_name}", 3, '2X', "worker")
      if !worker.empty?
        verifydomains = droplet.start_droplet("#{app_name}", 3, '1X', "verifydomains")
      end
    end
    # puts "starting redis cloud add-on on app #{app_name}"
    # droplet.update_redis_cloud("#{app_name}", 30)
    puts "app successfully started #{app_name}"
  end


  def rate_limit
    @client.rate_limit.info
  end
  #heroku migrate db
  #need to set up DO db migration
  def self.migrate_db(app_name)
    puts "migrate_db: the app name is #{app_name}"
    heroku = Heroku::API.new(:api_key => 'a73c9e7d-3e9c-44c7-9b87-c23aabdc1a7a')
    heroku = Heroku::API.new(:username => 'copybecker@gmail.com', :password => 'Fzero24!#')
    droplet.post_ps("#{app_name}", "rake db:migrate")
    sleep 5
    puts "migrate_db: database migrate and restarting app"
    droplet.post_ps("#{app_name}", "restart")
  end
  #Droplet config vars
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

    @client.config_var.update(to, db_hash)
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

  def get_redis_variables_for(app_name)7
    puts "getting librato env variables for the app #{app_name}"
    vars = config_vars(app_name)
    redis_url = vars['REDISCLOUD_URL']
    redis_hash = {redis_url: redis_url}
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
    @client.config_var.update('sourcerevive', release_and_slug_hash)
  end

  def delete_app(app_name)
    puts "delete app method for the app #{app_name}"
    if "#{app_name}".include?('revivecrawler')
      puts "DANGER THE APP #{app_name} IS BEING DELETED"
      @client.app.delete(app_name)
    end
  end

  def restart_app(app_name)
    puts 'restarting app'
    @client.droplet.restart_all(app_name)
  end

  def config_vars(app_name)
    @client.config_var.info(app_name)
  end

  def create_app(name)
    # logger.info "Creating #{name}"
    puts 'creating app'
    @client.app.create(name: name)

    droplet = DropletKit::Droplet.new(name: name, region: 'nyc2', image: 'ubuntu-14-04-x64', size: '512mb')
    created = client.droplets.create(droplet)
  end

  def copy_config(from, to)
    puts 'copying config'
    from_congig_vars = config_vars(from)
    from_congig_vars = from_congig_vars.except!('HEROKU_POSTGRESQL_RED_URL', 'HEROKU_POSTGRESQL_AMBER_URL', 'HEROKU_POSTGRESQL_BROWN_URL', 'HEROKU_POSTGRESQL_COPPER_URL', 'HEROKU_POSTGRESQL_NAVY_URL', 'HEROKU_POSTGRESQL_WHITE_URL', 'PROXIMO_URL', 'LIBRATO_USER', 'LIBRATO_PASSWORD', 'LIBRATO_TOKEN', 'REDISTOGO_URL', 'REDISCLOUD_URL')
    @client.config_var.update(to, from_congig_vars)
  end


  def copy_rack_and_rails_env_again(from, to)
    puts 'copying rack and rails env again'
    env_to_update = get_env_vars_for(from, ['RACK_ENV', 'RAILS_ENV'])
    env_to_update["REDIS_PROVIDER"] = 'REDISCLOUD_URL'
    @client.config_var.update(to, env_to_update) unless env_to_update.empty?
  end

  def get_env_vars_for(app_name, options=[])
    environments = {}
    options.each do |var|
      conf_var = @client.config_var.info(app_name)[var]
      if conf_var
        environments[var] = conf_var
      end
    end
    environments
  end

end
