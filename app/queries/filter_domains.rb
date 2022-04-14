class FilterDomains
  
  attr_reader :da, :pa, :citationflow, :trustflow, :refdomains, :backlinks, :price, :user_rating

  def initialize(params)
    if params
      params = params.reject{|k,v| v.to_f == 0}
      @pa = params['pa'].to_f if params['pa'].present?
      @da = params['da'].to_f  if params['da'].present?
      @citationflow = params['citationflow'].to_f if params['citationflow'].present?
      @trustflow = params['trustflow'].to_f if params['trustflow'].present?
      @refdomains = params['efdomains'].to_i if params['refdomains'].present?
      @backlinks = params['backlinks'].to_f if params['backlinks'].present?
      @price = params['price'].to_f if params['price'].present?
      @user_rating = params['user_rating'].to_f if params['user_rating'].present?
      @guarnateed = params['guaranteed'] if params['guaranteed'].present?
    end
  end
  
  def filter
    # raise
    domains = DomainForSale.using('main_shard').where('sold IS NOT TRUE AND sold IS NULL')
    domains = domains.where("pa > ?", @pa) if @pa.present?
    domains = domains.where("da > ?", @da) if @da.present?
    domains = domains.where("citationflow > ?", @citationflow) if @citationflow.present?
    domains = domains.where("trustflow > ?", @trustflow) if @trustflow.present?
    domains = domains.where("refdomains > ?", @refdomains) if @refdomains.present?
    domains = domains.where("backlinks > ?", @backlinks) if @backlinks.present?
    domains = domains.where("price > ?", @price) if @price.present?
    domains = domains.where("user_rating > ?", @user_rating) if @user_rating.present?
    domains = domains.where("guaranteed IS TRUE") if @guarnateed.present?
    return domains# .reorder(thumbs_up_count: :desc)
  end

end