class DomainsForSaleController < ApplicationController
  
  before_action :verify_paypal, only: [:new] 
  
  def index
    @domains = DomainForSale.using('main_shard').where('seller_id = ? AND sold IS NOT TRUE', current_user.id)
  end
  
  def sold
    @domains = DomainForSale.using('main_shard').where('seller_id = ? AND sold IS TRUE', current_user.id)
  end
  
  def purchased
    @domains = DomainForSale.using('main_shard').where('buyer_id = ? AND sold IS TRUE', current_user.id)
  end
  
  def new
    @domain = DomainForSale.new
  end

  def create
    # raise
    domain_id = params["domain_for_sale"]['domain_id']
    price = params["domain_for_sale"]['price']
    seller_notes = params["domain_for_sale"]['seller_notes']
    guaranteed = params["domain_for_sale"]['guaranteed'].to_i == 0 ? false : true
    # user_rating = current_user.rating.to_f == 0 ? 5.to_f : current_user.rating.to_f
    thumbs_down_count = current_user.thumbs_down_count.to_i
    thumbs_up_count = current_user.thumbs_up_count.to_i
    
    if params["domain_for_sale"]['url'].empty?
      
      processor_name = params["domain_for_sale"]['processor_name']
      crawl_id = params["domain_for_sale"]["crawl_id"]
      domain = Page.using("#{processor_name}").where(id: domain_id.to_i).first
      # domain = Page.where(id: domain_id.to_i).first

    else

      page_obj = Page.find_with_id(domain_id, params["domain_for_sale"]['url'])
      processor_name = page_obj['processor_name']
      crawl_id = page_obj['page'].crawl_id
      domain = page_obj['page']

    end
    
    suffix = Domainatrix.parse(domain.simple_url.to_s).public_suffix
    new_domain_for_sale = DomainForSale.using("main_shard").new(
                                          url: domain.simple_url.to_s, 
                                          citationflow: domain.citationflow.to_f, 
                                          trustflow: domain.trustflow.to_f,
                                          trustmetric: domain.trustmetric.to_f,
                                          pa: domain.pa.to_f,
                                          da: domain.da.to_f,
                                          refdomains: domain.refdomains.to_i,
                                          backlinks: domain.backlinks.to_i,
                                          crawl_id: domain.crawl_id,
                                          processor_name: processor_name.to_s,
                                          seller_id: current_user.id,
                                          price: price.to_f, 
                                          page_id: domain.id.to_i, 
                                          suffix: suffix,
                                          seller_paypal_email: current_user.paypal_email,
                                          seller_notes: seller_notes,
                                          thumbs_down_count: thumbs_down_count,
                                          thumbs_up_count: thumbs_up_count, 
                                          guaranteed: guaranteed
                                          )
                                          
    if new_domain_for_sale.save
      redirect_to domains_for_sale_index_path, notice: 'Domain Successfully Added To Marketplace'
    else
      redirect_to available_path(crawl_id.to_i, 'processor_name' => processor_name), alert: "We couldn't save the domain to the marketplace"
    end
  end
  
  def edit
    @domain = DomainForSale.new
  end
  
  def update
    domain = DomainForSale.using('main_shard').where(id: params[:id].to_i).first
    domain.update(price: params["domain_for_sale"]['price'].to_f) if domain && params["domain_for_sale"]['price'].to_f > 0
    redirect_to domains_for_sale_index_path, notice: 'Successfully Edited Domain'
  end
  
  def destroy
    domain = DomainForSale.using('main_shard').where(id: params[:id].to_i).first
    domain.destroy if domain
    redirect_to domains_for_sale_index_path, notice: 'Domain was removed from marketplace successfully'
  end
  
  private
  
  def verify_paypal
    redirect_to new_paypal_accounts_path(domain_id: params['domain_id'], processor_name: params['processor_name'], crawl_id: params['crawl_id']), notice: 'You must add your paypal email before being able to sell in the marketplace' if current_user.paypal_email.nil?
  end
  
end
