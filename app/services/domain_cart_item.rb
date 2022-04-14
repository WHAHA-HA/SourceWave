class DomainCartItem
  
  attr_reader :domain_id
  
  def initialize domain_id
    @domain_id = domain_id
  end
  
  def domain
    DomainForSale.using('main_shard').where(id: domain_id).first
  end
  
  def price
    domain.price
  end
  
end