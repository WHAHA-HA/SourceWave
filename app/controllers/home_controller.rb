class HomeController < ApplicationController

  def index
    render :layout => 'home'
  end

  def terms
    @header_class = "blue blue-unscrolled"
    render layout: 'sales'
  end

  def earnings_disclaimer
    @header_class = "blue blue-unscrolled"
    render layout: 'sales'
  end

  def general_disclaimer
    @header_class = "blue blue-unscrolled"
    render layout: 'sales'
  end

end
