class SitesController < ApplicationController
  before_filter :authorize

  # def index
  #   @available = Crawl.get_available_domains('user_id' => current_user.id)
  #   # @available = Crawl.get_available_domains('user_id' => params['user_id'])
  #   page = params[:page].nil? ? 1 : params[:page].to_i
  #   sort = params[:sort].nil? ? 2 : params[:sort].to_i
  #   @pages = @available.sort_by{|k|k[sort].to_i}.reverse.paginate(:page => page, :per_page => 25)
  # end

  def index
    # raise
    @nav = 'domains'
    domains, @da_range_str, @tf_range_str, @da_range_obj, @tf_range_obj = SortDomains.new(current_user.id, params).go
    @domains = domains.uniq.paginate(:page => params[:page], :per_page => 25)
  end

  def show
    @site = Site.using(:processor).find(params[:id])
    @stats_chart = Crawl.site_stats(params[:id])
  end

  def anchor_texts
    @crawl_id = params[:crawl_id]
  end

  def all_urls
    @site = Site.using(:processor).find(params[:id])
    @urls = @site.pages.limit(50).uniq
  end

  def delete
    DeleteDomains.new(params, current_user).go
    redirect_to sites_path('user_id' => current_user.id)
  end

  def broken
    @crawl = Crawl.using(params["processor_name"]).find(params[:id])
    # @broken = @crawl.pages.where(status_code: '404').limit(50).uniq
    @broken = @crawl.pages.where(status_code: '404')
    @pages = @broken.page(params[:page]).per_page(25)

    respond_to do |format|
      format.html
      format.csv { send_data @broken.to_csv }
    end

  end

  def available
    # rais
    @crawl = Crawl.using(params["processor_name"]).find(params[:id])

    if @crawl.status == 'running'
      @available = @crawl.save_available_sites
    elsif !@crawl.available_sites.empty? && @crawl.available_sites.count == @crawl.total_expired && @crawl.available_sites[0].count > 7
      @available = @crawl.available_sites
    else
      @available = @crawl.save_available_sites
    end

    page = params[:page].nil? ? 1 : params[:page].to_i
    sort = params[:sort].nil? ? 2 : params[:sort].to_i

    respond_to do |format|
      format.csv { send_data @crawl.available_to_csv }
      format.html { @pages = @available.sort_by{|k|k[sort].to_i}.reverse.paginate(:page => page, :per_page => 25) }
    end

  end

  def save_bookmarked
    Page.using(params["processor_name"]).where(id: params[:page_ids]).update_all(bookmarked: true)
    redirect_to bookmarked_sites_path(params[:id])
  end

  def unbookmark
    Page.using(params["processor_name"]).where(id: params[:page_ids]).update_all(bookmarked: false)
    redirect_to bookmarked_sites_path(params[:id])
  end

  def bookmarked
    @crawl = Crawl.using(params["processor_name"]).find(params[:id])
    sort = params[:sort].nil? ? 'id' : params[:sort]
    @bookmarked = @crawl.pages.where(bookmarked: true)
    @pages = @bookmarked.order("#{sort} DESC").page(params[:page]).per_page(25)

    respond_to do |format|
      format.html
      format.csv { send_data @bookmarked.to_csv }
    end

  end

end
