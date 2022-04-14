class PlansController < ApplicationController

  def index
    @header_class = 'blue'
    render :layout => 'sales'
  end

  def plansv2
    @header_class = 'blue'
    render :layout => 'sales'
  end

  def secret_squirrel
    render :layout => 'home'
  end

  def upgrade_plan
  end

end
