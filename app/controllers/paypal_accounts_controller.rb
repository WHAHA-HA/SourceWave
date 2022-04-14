class PaypalAccountsController < ApplicationController
  
  def new
  end

  def create
    current_user.update(paypal_email: params['user']['paypal_email'])
    if params['user']['domain_id'] != "" && params['user']['processor_name'] != ""
      redirect_to new_domains_for_sale_path(domain_id: params['user']['domain_id'].to_i, processor_name: params['user']["processor_name"], crawl_id: params['user']["crawl_id"])
    else
      redirect_to dashboard_path
    end
  end
  
end
