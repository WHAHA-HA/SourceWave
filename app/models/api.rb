class Api
  require 'json'

  def self.start_crawl(options = {})
    processor_name = options['processor_name']
    puts "the processor_name is #{options['processor_name']}"
    crawl = Crawl.using("#{processor_name}").where(id: options['crawl_id'].to_i).first
    puts "start crawl: #{crawl}"
    if crawl

      Octopus.setup do |config|
        config.shards = {:main_shard => {
                          :adapter => 'postgresql',
                          :database => 'd43keikloc7ejh',
                          :username => 'uda0tbtpqg53lu',
                          :password => 'pfulh5el80spt6ehv206vs9qs1u',
                          :host => 'ec2-107-20-155-89.compute-1.amazonaws.com',
                          :port => 5532,
                          :pool => 1
                        },
                        :processor => {
                          :adapter => 'postgresql',
                          :database => 'd570jqv21u9in0',
                          :username => 'u5fkjshgbhhncg',
                          :password => 'p843pa73aoj8sm9sb4pj4ol72vo',
                          :host => 'ec2-54-163-234-153.compute-1.amazonaws.com',
                          :port => 5432,
                          :pool => 1
                        },
                        :processor_one => {
                          :adapter => 'postgresql',
                          :database => 'dbdfeisb2cpu9o',
                          :username => 'u42cj46ifes9mp',
                          :password => 'p7sgm4r42gq8niengm8ignn2pt7',
                          :host => 'ec2-54-163-236-202.compute-1.amazonaws.com',
                          :port => 5542,
                          :pool => 1
                        },
                        :processor_two => {
                          :adapter => 'postgresql',
                          :database => 'd9po7h5a2tkblk',
                          :username => 'u4p8o1fm5l007q',
                          :password => 'p48p6ff9atah28dm360flr4g3sq',
                          :host => 'ec2-54-163-237-255.compute-1.amazonaws.com',
                          :port => 5502,
                          :pool => 1
                        },
                        :processor_three => {
                          :adapter => 'postgresql',
                          :database => 'ddl8pqb6olhsh7',
                          :username => 'u1230jnk7rhe6j',
                          :password => 'p9alv86sk57jb14jed8vuuqr41h',
                          :host => 'ec2-23-21-207-111.compute-1.amazonaws.com',
                          :port => 5452,
                          :pool => 1
                        },
                        :processor_four => {
                          :adapter => 'postgresql',
                          :database => 'dd2a4lld9f69j2',
                          :username => 'u7r3qia870f4ea',
                          :password => 'p6ku9ua71s44j598umh2iln6ied',
                          :host => 'ec2-54-163-239-48.compute-1.amazonaws.com',
                          :port => 5432,
                          :pool => 1
                        }
                      }
      end


      begin
        puts 'db migration was sucessful '
        app_name = options['app_name']

        if Rails.env.development?
          uri = URI.parse("http://localhost:3000/api_create")
          puts "production start #{app_name}"
        else
          unless options['is_do'].present?
            uri = URI.parse("http://#{app_name}.herokuapp.com/api_create")
          else
            #app_name should be there
            uri = URI.parse("http://104.131.19.152:3000/api_create")
          end
          puts "production start #{app_name}"
        end

        post_params = {
          :options => options
        }

        # Convert the parameters into JSON and set the content type as application/json
        req = Net::HTTP::Post.new(uri.path)
        req.body = JSON.generate(post_params)

        http = Net::HTTP.new(uri.host, uri.port)
        response = http.start {|htt| htt.request(req)}

      rescue
        # puts 'retrying db migration'
        # Api.delay.migrate_db(crawl_id: crawl.id)
        # Api.delay_for(1.minute).start_crawl(crawl_id: crawl.id)
        #
        app = crawl.heroku_app
        puts 'new app did not start properly'
        app.update(status: 'retry')
        Crawl.using("#{processor_name}").update(crawl.id, status: 'retry')
        heroku = HerokuPlatform.new
        number_of_apps_running = heroku.app_list.count
        heroku.delete_app(crawl.heroku_app.name)
        ForkNewApp.delay.retry(app.id, number_of_apps_running, 'processor_name' => processor_name)

      end

    end

  end

  def self.migrate_db(options = {})
    processor_name = options['processor_name']
    crawl = Crawl.using("#{processor_name}").where(id: options[:crawl_id].to_i).first

    if crawl
      app_name = crawl.heroku_app.name

      if Rails.env.development?
        uri = URI.parse("http://localhost:3000/migrate_db")
        puts "production start #{app_name}"
      else
        unless options['is_do'].present?
          uri = URI.parse("http://#{app_name}.herokuapp.com/migrate_db")
        else
          #there should be app(droplet) ID(IP) for db migration, set default
          uri = URI.parse("http://104.131.19.152:3000/migrate_db")
        end
        puts "production start #{app_name}"
      end

      post_params = {
        :options => options
      }

      # post_params = {
      #   :user_id => user_id,
      #   :urls => urls,
      #   :options => options
      # }

      # Convert the parameters into JSON and set the content type as application/json
      req = Net::HTTP::Post.new(uri.path)
      req.body = JSON.generate(post_params)
      #req["Content-Type"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.start {|htt| htt.request(req)}

    end

  end

  def self.process_new_crawl(options={})
    if Rails.env.development?
      uri = URI.parse("http://localhost:3000/process_new_crawl")
      puts 'processing new crawl local'
    else
      unless options['is_do'].present?
        uri = URI.parse("http://reviveprocessor.herokuapp.com/process_new_crawl")
      else
        #master process droplet URL
        uri = URI.parse("http://104.131.19.152:3000/process_new_crawl")
      end
      puts 'processing new crawl production'
    end

    post_params = {
      :options => options
    }

    # Convert the parameters into JSON and set the content type as application/json
    req = Net::HTTP::Post.new(uri.path)
    req.body = JSON.generate(post_params)
    #req["Content-Type"] = "application/json"

    http = Net::HTTP.new(uri.host, uri.port)
    response = http.start {|htt| htt.request(req)}
  end

  def self.stop_crawl(options={})
    if Rails.env.development?
      uri = URI.parse("http://localhost:3000/shut_down_crawl")
      puts 'shutting down crawl local'
    else
      unless options['is_do'].present?
        uri = URI.parse("http://reviveprocessor.herokuapp.com/shut_down_crawl")
      else
        uri = URI.parse("http://104.131.19.152:3000/shut_down_crawl")
      end
      puts 'shutting down crawl production'
    end

    post_params = {
      :options => options
    }

    # Convert the parameters into JSON and set the content type as application/json
    req = Net::HTTP::Post.new(uri.path)
    req.body = JSON.generate(post_params)

    http = Net::HTTP.new(uri.host, uri.port)
    response = http.start {|htt| htt.request(req)}
  end

  def self.toggle_user_status(options={})
    Api.do_post(options, 'admins/toggle_user_status')
  end

  private

  def self.do_post(options={}, controller_action)
    #post action ,check is_do
    uri = Rails.env.development? ? URI.parse("http://dev-120212.nitrousapp.com:3000/#{controller_action}") : URI.parse("http://reviveprocessor.herokuapp.com/#{controller_action}")

    uri = URI.parse("http://104.131.19.152:3000/#{controller_action}") if options['is_do'].present? && !Rails.env.development?

    post_params = {
      options: options
    }

    # Convert the parameters into JSON and set the content type as application/json
    req = Net::HTTP::Post.new(uri.path)
    req.body = JSON.generate(post_params)

    http = Net::HTTP.new(uri.host, uri.port)
    response = http.start {|htt| htt.request(req)}
  end

end
