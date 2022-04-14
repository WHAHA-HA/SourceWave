class DomainsCart
  
  attr_reader :items
  
  def self.build_from_hash hash
    items = if hash['cart'] then
      hash['cart']['items'].map do |item_data|
        DomainCartItem.new item_data['domain_id']
      end
    else
      []
    end
    
    new items
  end
  
  def initialize items = []
    @items = items
  end
  
  def add_item domain_id
    @items << DomainCartItem.new(domain_id)
  end
  
  def empty?
    @items.empty?
  end
  
  def serialize
    items = @items.map do |item| 
      {
        "domain_id" => item.domain_id
      } 
    end
    
    {
      'items' => items
    }
  end
  
  def total_price
    @items.inject(0) {|sum, item| sum + item.price}
  end
  
end