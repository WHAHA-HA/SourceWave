class MarketplaceController < ApplicationController
  before_filter :check_active_subscription
  before_filter :initialize_cart

  def index
    # raise
    sort_by = params[:sort].nil? ? 'created_at' : params[:sort]

    # @order = params[:order].nil? ? 'desc' : params[:order]
    # case order_param
    # when nil
    #   @order = 'desc'
    #   order = 'desc'
    # when 'desc'
    #   @order = 'asc'
    #   order = 'desc'
    # when 'asc'
    #   @order = 'desc'
    #   order = 'asc'
    # end

    @domains = FilterDomains.new(params[:domain_for_sale]).filter.reorder(sort_by => 'desc').paginate(:page => params[:page], :per_page => 25)
  end

end
