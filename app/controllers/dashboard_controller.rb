class DashboardController < ApplicationController
  before_filter :authorize
  before_action :check_active_subscription

  before_action :maintenance

  def index
    if params['reactivate'] == 'true'
      redirect_to reactivate_path
    else
      @dashboard = current_user.user_dashboard
      @domains = Page.find(@dashboard.top_domains)
    end

  end

  def maintenance
    @maintenance = Maintenance.first
  end
end
