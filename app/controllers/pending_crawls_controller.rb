class PendingCrawlsController < ApplicationController
  before_action :authorize, :except => [:sort]
  
  def index
    
    processor_names = ['processor', 'processor_one', 'processor_two']
    crawls_array = []
    processor_names.each do |processor|
      crawls_array << HerokuApp.using("#{processor}").where(status: 'pending', user_id: current_user.id).order(:position).includes(:crawl).flatten
    end
    page = params[:page].nil? ? 1 : params[:page]
    @crawls = crawls_array.flatten.paginate(:page => page, :per_page => 10)
    
    # @crawls = HerokuApp.using(:processor).where(status: "pending", user_id: current_user.id).order(:position).includes(:crawl)
  end
  
  def sort
    params[:heroku_app].each_with_index do |id, index|
      HerokuApp.using(:processor).update(id, position: index+1)
    end
    render nothing: true
  end
  
end
