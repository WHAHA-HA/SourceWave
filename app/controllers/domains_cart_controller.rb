class DomainsCartController < ApplicationController
  before_filter :initialize_cart
  before_filter :verify_domain, only: [:verify_domain]
  before_filter :verify_domain_key, only: [:thank_you]
  before_filter :verify_user, only: [:add_domain_to_cart]

  def index
    @domains = @cart.items.map{|cart_item| cart_item.domain}
  end
  
  def verify_domain
    # raise
    url = DomainForSale.using(:main_shard).where(id: params[:domain_id].to_i).first.url
    domain_is_available = Whois.whois("#{url}").available? unless url.empty?
    response = Unirest.get "http://whois.domaintools.com/#{url}"
    domain_tools_is_available = !Nokogiri::HTML(response.raw_body).at_css('.domain-available').nil?
    
    puts "the domain verification response is #{domain_is_available}"
    if domain_is_available == true && domain_tools_is_available == true
      redirect_to PaypalCheckout.new(params[:seller_paypal], params[:domain_id].to_i, params[:price].to_f, params[:redirect_url]).url
    else
      redirect_to domains_cart_index_path, notice: 'Sorry :( This Domain Has Already Been Registered'
    end
    
  end
  
  def add_domain_to_cart
    @cart.add_item params[:id]
    session['cart'] = @cart.serialize
    redirect_to domains_cart_index_path, notice: 'Domain Successfully Added To Cart'
  end
  
  def thank_you
    # raise
    @domain_bought = DomainForSale.using('main_shard').where(id: params['domain_id'].to_i).first
    @domain_bought.update(sold: true, buyer_id: current_user.id) if @domain_bought
    domain_sold = Page.using("#{@domain_bought.processor_name}").where(id: @domain_bought.page_id).first
    domain_sold.update(sold: true) if domain_sold
    # session['cart'] = {'items' => []}
    if !session['cart'].nil?
      new_session_cart = session['cart']['items'].reject{|d| d['domain_id'].to_i == params['domain_id'].to_i}
      session['cart'] = {'items' => new_session_cart}
    end
  end
  
  def leave_review
    # raise
    # buyer_rating = params['user']['rating']
    seller = User.using('main_shard').where(id: params['user']['seller_id'].to_i).first
    # seller_rating = seller.rating.nil? ? 5 : seller.rating.to_f
    # updated_rating = ((seller_rating + buyer_rating)/2).to_f
    if params['user']['rating'] == 'thumbs_up'
      new_rating = seller.thumbs_up_count.to_i + 1
      seller.update(thumbs_up_count: new_rating)
      DomainForSale.using(:main_shard).where(seller_id: seller.id).update_all(thumbs_up_count: new_rating)
    else
      new_rating = seller.thumbs_down_count.to_i + 1
      seller.update(thumbs_down_count: new_rating)
      DomainForSale.using(:main_shard).where(seller_id: seller.id).update_all(thumbs_down_count: new_rating)
    end
    

    if params['commit'] == "View Purchased Domains"
      redirect_to marketplace_index_path
    else
      redirect_to marketplace_index_path
    end
    
  end
  
  private
  
  def verify_domain_key
    redirect_to marketplace_index_path unless params['key'] == Digest::SHA1.hexdigest(params['domain_id'].to_s)
  end
  
  def verify_user
    redirect_to new_basic_subscription_path, notice: 'Create an account before purchasing a domain name' if current_user.nil?
  end

end